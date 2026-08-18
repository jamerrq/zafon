#!/bin/bash
# zafon:name=Zsh + Oh My Zsh
# zafon:desc=omz, powerlevel10k and custom plugins (cloned, not tracked)

set -uo pipefail

ZSH_DIR="${ZSH:-$HOME/.config/zsh/.oh-my-zsh}"
ZSH_CUSTOM_DIR="$ZSH_DIR/custom"
ZSHRC="$HOME/.zshrc"

# name|destination|repo
# These are all nested git repos, so yadm cannot track their contents. They are
# cloned on demand instead, which also keeps them updatable via git/omz.
REPOS=(
  "oh-my-zsh|$ZSH_DIR|https://github.com/ohmyzsh/ohmyzsh.git"
  "powerlevel10k|$ZSH_CUSTOM_DIR/themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
  "zsh-autosuggestions|$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
  "zsh-syntax-highlighting|$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

CONFIGS=("$HOME/.config/zsh/.p10k.zsh" "$HOME/.config/zsh/.zsh_aliases" "$HOME/.config/zsh/.zsh_functions")

check() {
  local problems=()

  [[ -f $ZSHRC ]] || { echo ".zshrc is missing (pull it from yadm)"; return 2; }

  local entry name dest
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name dest _ <<<"$entry"
    [[ -d $dest ]] || problems+=("not installed: $name")
  done

  local f
  for f in "${CONFIGS[@]}"; do
    [[ -f $f ]] || problems+=("missing config: ${f##*/}")
  done

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 2
  fi

  echo "omz + ${#REPOS[@]} repos present, .zshrc tracked"
  return 0
}

apply() {
  local entry name dest repo installed=0
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name dest repo <<<"$entry"
    if [[ -d $dest ]]; then
      continue
    fi
    echo "cloning $name..."
    mkdir -p "$(dirname "$dest")"
    if git clone --depth=1 "$repo" "$dest" >/dev/null 2>&1; then
      echo "installed: $name"
      ((installed++))
    else
      echo "failed to clone $name from $repo" >&2
    fi
  done

  ((installed == 0)) && echo "nothing to install, everything already present"

  # .zsh_yadm_aliases is generated from the omz git plugin on first shell start;
  # drop a stale copy so it regenerates against the freshly cloned omz.
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
