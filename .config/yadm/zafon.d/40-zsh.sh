#!/bin/bash
# zafon:name=Zsh + Oh My Zsh
# zafon:desc=ZDOTDIR layout, omz + plugins, and a real interactive-shell load test

# Two halves. The first is the usual "is it installed" check: the nested git
# repos omz needs, and the tracked config files. The second actually starts an
# interactive zsh and asks it what it loaded -- because every failure worth
# catching here is one where the files are all present and the shell still does
# not end up in the intended state.
#
# The layout this enforces: ~/.zshenv is the only zsh file in $HOME, and it
# exists to point ZDOTDIR at ~/.config/zsh. Everything else, config and
# generated state alike, lives there.

set -uo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/shell-probe.sh"

ZDOTDIR_EXPECTED="$HOME/.config/zsh"
ZSHENV="$HOME/.zshenv"
ZSH_DIR="$ZDOTDIR_EXPECTED/.oh-my-zsh"
ZSH_CUSTOM_DIR="$ZSH_DIR/custom"

# name|destination|repo -- all nested git repos, so yadm cannot track their
# contents. Cloned on demand, which also keeps them updatable via git/omz.
REPOS=(
  "oh-my-zsh|$ZSH_DIR|https://github.com/ohmyzsh/ohmyzsh.git"
  "powerlevel10k|$ZSH_CUSTOM_DIR/themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
  "zsh-autosuggestions|$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
  "zsh-syntax-highlighting|$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

CONFIGS=(.zshrc .p10k.zsh .zsh_aliases .zsh_functions)

# One shell start answers every question below. Note yss is checked as a
# FUNCTION, not an alias: the tail of .zsh_aliases deliberately unaliases every
# g*/y* alias and redefines it as a function that echoes the command first, so
# asserting on $+aliases[yss] would report a false failure.
PROBE_SNIPPET='
echo zdotdir=$ZDOTDIR
echo histfile=$HISTFILE
echo compdump=$ZSH_COMPDUMP
echo omz=$(( $+functions[omz] ))
# $+functions[p10k] is 1 whenever ZSH_THEME loads the theme, whether or not
# .p10k.zsh was sourced -- it cannot tell a missing prompt CONFIG from a
# working one. POWERLEVEL9K_LEFT_PROMPT_ELEMENTS is set only by the config.
echo p10k=$(( $+functions[p10k] ))
echo p10kconf=$(( $+POWERLEVEL9K_LEFT_PROMPT_ELEMENTS ))
echo yadmfn=$(( $+functions[yss] ))
echo autosuggest=$(( $+ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE ))
echo highlight=$(( $+ZSH_HIGHLIGHT_STYLES ))
typeset -U u; u=($path); echo pathdupes=$(( ${#path} - ${#u} ))
'

check() {
  local problems=()

  # ---- layout ----
  if [[ ! -f $ZSHENV ]]; then
    problems+=("~/.zshenv is missing -- without it ZDOTDIR is unset and zsh falls back to \$HOME")
  elif ! grep -q 'ZDOTDIR' "$ZSHENV"; then
    problems+=("~/.zshenv does not set ZDOTDIR")
  fi

  [[ -e $HOME/.zshrc ]] &&
    problems+=("~/.zshrc still exists; with ZDOTDIR set it is dead weight and \$ZDOTDIR/.zshrc is what loads")

  local f
  for f in "${CONFIGS[@]}"; do
    [[ -f $ZDOTDIR_EXPECTED/$f ]] || problems+=("missing config: ${f}")
  done

  # ---- upstream repos ----
  local entry name dest
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name dest _ <<<"$entry"
    [[ -d $dest ]] || problems+=("not installed: $name")
  done

  # Stale generated state back in $HOME means something bypassed ZDOTDIR.
  local strays
  strays=$(find "$HOME" -maxdepth 1 \( -name '.zcompdump*' -o -name '.zsh_history' \) 2>/dev/null | wc -l)
  ((strays)) && problems+=("$strays zsh state file(s) still in \$HOME rather than \$ZDOTDIR")

  # If anything above is missing, starting a shell will only produce noise.
  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  # ---- does it actually load? ----
  local errs out
  errs=$(shell_probe_stderr zsh)
  [[ -n $errs ]] && problems+=("interactive zsh prints on startup: ${errs//$'\n'/; }")

  out=$(shell_probe zsh "$PROBE_SNIPPET")
  if [[ -z $out ]]; then
    problems+=("interactive zsh produced no output -- it did not start")
  else
    [[ $(probe_kv "$out" zdotdir) == "$ZDOTDIR_EXPECTED" ]] ||
      problems+=("ZDOTDIR is '$(probe_kv "$out" zdotdir)', expected $ZDOTDIR_EXPECTED")
    [[ $(probe_kv "$out" histfile) == "$ZDOTDIR_EXPECTED"/* ]] ||
      problems+=("HISTFILE is outside \$ZDOTDIR: $(probe_kv "$out" histfile)")
    [[ $(probe_kv "$out" compdump) == "$ZDOTDIR_EXPECTED"/* ]] ||
      problems+=("ZSH_COMPDUMP is outside \$ZDOTDIR: $(probe_kv "$out" compdump)")
    [[ $(probe_kv "$out" p10k) == 1 ]] || problems+=("powerlevel10k did not load")
    [[ $(probe_kv "$out" p10kconf) == 1 ]] || problems+=("the .p10k.zsh prompt config was not sourced")
    [[ $(probe_kv "$out" yadmfn) == 1 ]] || problems+=("the y* yadm functions are not defined")
    [[ $(probe_kv "$out" autosuggest) == 1 ]] || problems+=("zsh-autosuggestions did not load")
    [[ $(probe_kv "$out" highlight) == 1 ]] || problems+=("zsh-syntax-highlighting did not load")
    [[ $(probe_kv "$out" pathdupes) == 0 ]] ||
      problems+=("PATH has $(probe_kv "$out" pathdupes) duplicate entries")
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "ZDOTDIR layout, ${#REPOS[@]} repos, and a clean interactive load"
  return 0
}

apply() {
  local entry name dest repo installed=0
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name dest repo <<<"$entry"
    [[ -d $dest ]] && continue
    echo "cloning $name..."
    mkdir -p "$(dirname "$dest")"
    if git clone --depth=1 "$repo" "$dest" >/dev/null 2>&1; then
      echo "installed: $name"
      ((installed++))
    else
      echo "failed to clone $name from $repo" >&2
    fi
  done

  # Move state that predates the ZDOTDIR move rather than deleting it: the
  # history file is the one thing here that cannot be regenerated.
  if [[ -f $HOME/.zsh_history && ! -f $ZDOTDIR_EXPECTED/.zsh_history ]]; then
    mv "$HOME/.zsh_history" "$ZDOTDIR_EXPECTED/.zsh_history"
    echo "moved .zsh_history into \$ZDOTDIR"
  fi
  # Completion dumps are rebuilt on the next shell start, and carry the zsh
  # version in their name, so stale ones are just litter.
  local n
  n=$(find "$HOME" -maxdepth 1 -name '.zcompdump*' -delete -print 2>/dev/null | wc -l)
  ((n)) && echo "removed $n stale completion dump(s) from \$HOME"

  ((installed == 0)) && echo "nothing to install, everything already present"
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
