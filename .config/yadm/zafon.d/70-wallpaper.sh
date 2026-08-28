#!/bin/bash
# zafon:name=Wallpaper
# zafon:desc=offer the tux wallpaper, leaving the current one if declined
# zafon:optional=true

# Marked optional deliberately: this is a taste decision, not a correctness one,
# so unattended runs (--yes) leave whatever wallpaper is already set alone.
#
# Quattro moved the state that this reads. Both the current-background symlink
# and theme.name used to sit under ~/.config/omarchy/current/; they are now in
# ~/.local/state/omarchy/current/. Pointing at the old paths made current_theme
# return empty, which this module reported as "no active theme" and -- because
# that path returned 0 -- counted as OK. That is why zafon kept saying
# everything was in place while never actually setting the wallpaper.

set -uo pipefail

PREFERRED="gruvbox_tux.png"
CURRENT_LINK="$HOME/.local/state/omarchy/current/background"
THEME_NAME_FILE="$HOME/.local/state/omarchy/current/theme.name"

current_theme() { cat "$THEME_NAME_FILE" 2>/dev/null; }

preferred_path() {
  local theme
  theme=$(current_theme)
  [[ -n $theme ]] || return 1
  printf '%s\n' "$HOME/.config/omarchy/backgrounds/$theme/$PREFERRED"
}

check() {
  local theme target current

  theme=$(current_theme)
  if [[ -z $theme ]]; then
    # A missing theme.name is a real problem now, not a shrug: every other
    # theme-derived path is built from it.
    echo "no active theme recorded at $THEME_NAME_FILE"
    return 2
  fi

  target=$(preferred_path)
  if [[ ! -f $target ]]; then
    echo "$PREFERRED not present in theme '$theme' (50-theme syncs it there)"
    return 2
  fi

  current=$(readlink -f "$CURRENT_LINK" 2>/dev/null)
  if [[ -z $current ]]; then
    echo "no background is set for theme '$theme'; tux is available"
    return 1
  fi
  if [[ $current == "$target" ]]; then
    echo "tux wallpaper is set (theme: $theme)"
    return 0
  fi

  # Not an error -- just a different choice. Reported as drift so that apply
  # offers the swap, and declining leaves the current wallpaper untouched.
  echo "currently ${current##*/}; tux is available if you want it"
  return 1
}

apply() {
  local target
  target=$(preferred_path) || { echo "no active theme" >&2; return 1; }

  if [[ ! -f $target ]]; then
    echo "$PREFERRED not found at $target" >&2
    return 1
  fi

  if omarchy-theme-bg-set "$target" >/dev/null 2>&1; then
    echo "set wallpaper to $PREFERRED"
    return 0
  fi

  echo "omarchy-theme-bg-set failed" >&2
  return 1
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
