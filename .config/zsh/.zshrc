# Read from $ZDOTDIR (~/.config/zsh), set in ~/.zshenv.

# Powerlevel10k instant prompt. Must stay near the top: anything that writes to
# the console or reads input has to run above it.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# Generated state
#
# Keep it beside this file rather than in $HOME. The compdump name carries the
# host and zsh version, so a zsh upgrade leaves the old one behind -- which is
# how $HOME ended up with three versions' worth. Both are gitignored.
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
ZSH_COMPDUMP="$ZDOTDIR/.zcompdump-${HOST}-${ZSH_VERSION}"

# ---------------------------------------------------------------------------
# Oh My Zsh
#
# $ZSH is under ~/.config/zsh, not the default ~/.oh-my-zsh. omz, p10k and the
# two plugins are nested git repos, so yadm cannot track their contents;
# zafon.d/40-zsh.sh clones them when missing.
export ZSH="$ZDOTDIR/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode auto

# omz sources each of these itself -- listing them here is the whole
# installation step, so do not also source the plugin files by hand below.
plugins=(
  git fzf branch zsh-autosuggestions zsh-syntax-highlighting bgnotify sudo
)

source "$ZSH/oh-my-zsh.sh"
source "$ZDOTDIR/.p10k.zsh"

# ---------------------------------------------------------------------------
# PATH
#
# `typeset -U path` keeps the array unique, so entries can be added freely
# without accumulating duplicates. Everything goes through this one array:
# a later `export PATH="...:$PATH"` would silently defeat the uniqueness.
typeset -U path

my_paths=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/fnm"
  "$HOME/.bun/bin"
  "$HOME/.deno/bin"
  "$HOME/.cargo/bin"
  "$HOME/.pyenv/bin"
  "$HOME/.lmstudio/bin"
)

# Only real directories, so a machine without bun or deno gets a clean PATH.
for p in $my_paths; do
  [[ -d $p ]] && path=("$p" $path)
done
export PATH="${(j/:/)path}"

# ---------------------------------------------------------------------------
# Tools
#
# Each guarded: an absent tool should not print an error on every new shell.
command -v fnm >/dev/null 2>&1 && eval "$(fnm env)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - zsh)"

export BUN_INSTALL="$HOME/.bun"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# ---------------------------------------------------------------------------
# Aliases and functions

[[ -f "$ZDOTDIR/.zsh_aliases" ]] && source "$ZDOTDIR/.zsh_aliases"
[[ -f "$ZDOTDIR/.zsh_functions" ]] && source "$ZDOTDIR/.zsh_functions"

# ---------------------------------------------------------------------------
# Environment

export EDITOR=nvim
export SUDO_EDITOR=nvim
export EZA_ICONS_AUTO=true
export EZA_COLORS_AUTO=true

# Refuse to clobber an existing file with `>`. Use `>|` to override.
set -o noclobber
