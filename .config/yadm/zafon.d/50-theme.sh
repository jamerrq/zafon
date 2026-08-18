#!/bin/bash
# zafon:name=Theme
# zafon:desc=rounded mako/walker templates, FiraCode font, custom wallpapers

set -uo pipefail

MAKO_TPL="$HOME/.config/omarchy/themed/mako.ini.tpl"
WALKER_TPL="$HOME/.config/omarchy/themed/walker.css.tpl"
WALLPAPER_SRC="$HOME/.config/yadm/wallpapers"
THEME_NAME_FILE="$HOME/.config/omarchy/current/theme.name"
FONT="FiraCode Nerd Font"

current_theme() { cat "$THEME_NAME_FILE" 2>/dev/null; }

check() {
  local problems=()

  if [[ -f $MAKO_TPL ]]; then
    grep -qF "border-radius=10" "$MAKO_TPL" || problems+=("mako template lost border-radius=10")
  else
    problems+=("mako template is missing")
  fi

  if [[ -f $WALKER_TPL ]]; then
    grep -qF "border-radius: 10px;" "$WALKER_TPL" || problems+=("walker template lost border-radius")
  else
    problems+=("walker template is missing")
  fi

  local font
  font=$(omarchy-font-current 2>/dev/null)
  [[ $font == *FiraCode* ]] || problems+=("system font is '${font:-unknown}', not $FONT")

  local theme
  theme=$(current_theme)
  if [[ -n $theme && -d $WALLPAPER_SRC ]]; then
    local dest="$HOME/.config/omarchy/backgrounds/$theme"
    local missing=0 w
    for w in "$WALLPAPER_SRC"/*; do
      [[ -e $w ]] || continue
      [[ -e "$dest/$(basename "$w")" ]] || ((missing++))
    done
    ((missing)) && problems+=("$missing wallpaper(s) not synced into theme '$theme'")
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "templates, $FONT and wallpapers all in place (theme: ${theme:-none})"
  return 0
}

apply() {
  local font
  font=$(omarchy-font-current 2>/dev/null)
  if [[ $font != *FiraCode* ]]; then
    omarchy-font-set "$FONT" >/dev/null 2>&1 && echo "set system font to $FONT"
  fi

  local theme
  theme=$(current_theme)
  if [[ -n $theme && -d $WALLPAPER_SRC ]]; then
    local dest="$HOME/.config/omarchy/backgrounds/$theme"
    mkdir -p "$dest"
    # -u so an edited wallpaper in the theme dir is not needlessly re-copied
    cp -u "$WALLPAPER_SRC"/* "$dest/" 2>/dev/null
    echo "synced wallpapers into theme '$theme'"
  fi

  omarchy-theme-refresh >/dev/null 2>&1 && echo "recompiled theme templates"

  local tux="$HOME/.config/omarchy/backgrounds/$theme/gruvbox_tux.png"
  if [[ -n $theme && -f $tux ]]; then
    omarchy-theme-bg-set "$tux" >/dev/null 2>&1 && echo "set tux wallpaper"
  fi

  makoctl reload >/dev/null 2>&1
  omarchy-restart-walker >/dev/null 2>&1
  echo "reloaded mako and walker"
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
