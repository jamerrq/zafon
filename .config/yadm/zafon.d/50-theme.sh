#!/bin/bash
# zafon:name=Theme
# zafon:desc=thick borders on the shell surfaces, FiraCode font, custom wallpapers

# Quattro deleted both apps this module used to configure. mako is not even
# installed any more and walker is no longer the launcher; notifications, the
# launcher and the menus are all Quickshell surfaces inside omarchy-shell now.
# So ~/.config/omarchy/themed/{mako.ini,walker.css}.tpl are inert -- Omarchy
# ships no templates by those names for them to override.
#
# The replacement is better than what it replaced. Corner radius is not set
# here at all: the shell mirrors Hyprland's decoration:rounding into
# Style.cornerRadius, so the single value in hypr/looknfeel.lua rounds
# notifications, the launcher, the menus and every bar flyout (10-hypr checks
# it). Only the border WIDTHS need declaring, and because user keys in
# ~/.config/omarchy/shell.toml beat the theme's own copy, they survive a theme
# switch instead of needing to be re-rendered on every `omarchy theme set`.

set -uo pipefail

SHELL_TOML="$HOME/.config/omarchy/shell.toml"
WALLPAPER_SRC="$HOME/.config/yadm/wallpapers"
THEME_NAME_FILE="$HOME/.local/state/omarchy/current/theme.name"
FONT="FiraCode Nerd Font"
BORDER_WIDTH=4

# The surfaces that took over from mako (notifications) and walker (menu), plus
# the bar flyouts, kept consistent with them.
SECTIONS=(notifications menu popups)

current_theme() { cat "$THEME_NAME_FILE" 2>/dev/null; }

section_width() {
  # Print the border-width declared under [$1], or nothing if the section or
  # the key is absent. awk keeps this to one pass and no TOML parser.
  awk -v want="[$1]" '
    /^[[:space:]]*\[/ { in_section = ($0 ~ "^[[:space:]]*\\" want) ; next }
    in_section && /^[[:space:]]*border-width[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, ""); gsub(/[[:space:]]/, ""); print; exit
    }
  ' "$SHELL_TOML" 2>/dev/null
}

check() {
  local problems=()

  if [[ ! -f $SHELL_TOML ]]; then
    problems+=("shell.toml is missing (pull it from yadm)")
  else
    local section width
    for section in "${SECTIONS[@]}"; do
      width=$(section_width "$section")
      if [[ -z $width ]]; then
        problems+=("[$section] has no border-width in shell.toml")
      elif [[ $width != "$BORDER_WIDTH" ]]; then
        problems+=("[$section] border-width is $width, expected $BORDER_WIDTH")
      fi
    done
  fi

  local font
  font=$(omarchy-font-current 2>/dev/null)
  [[ $font == *FiraCode* ]] || problems+=("system font is '${font:-unknown}', not $FONT")

  local theme
  theme=$(current_theme)
  if [[ -z $theme ]]; then
    problems+=("no active theme recorded at $THEME_NAME_FILE")
  elif [[ -d $WALLPAPER_SRC ]]; then
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

  echo "border-width $BORDER_WIDTH on ${#SECTIONS[@]} surfaces, $FONT, wallpapers synced (theme: $theme)"
  return 0
}

apply() {
  local changed=0

  # Append any missing section rather than rewriting the file: shell.toml also
  # carries [font] and anything else hand-tuned, and there is no merge here.
  if [[ -f $SHELL_TOML ]]; then
    local section width
    for section in "${SECTIONS[@]}"; do
      width=$(section_width "$section")
      [[ $width == "$BORDER_WIDTH" ]] && continue
      if [[ -z $width ]]; then
        printf '\n[%s]\nborder-width = %s\n' "$section" "$BORDER_WIDTH" >>"$SHELL_TOML"
        echo "added [$section] border-width = $BORDER_WIDTH"
      else
        echo "[$section] border-width is $width, not $BORDER_WIDTH -- edit shell.toml by hand" >&2
      fi
      changed=1
    done
  else
    echo "cannot apply: $SHELL_TOML is missing" >&2
    return 1
  fi

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

  # Choosing the wallpaper is deliberately not done here -- see 70-wallpaper.sh,
  # which asks rather than overriding whatever is currently set.

  # shell.toml is watched and hot-reloads; restart only if we touched it.
  if ((changed)) && command -v omarchy-restart-shell >/dev/null 2>&1; then
    omarchy-restart-shell >/dev/null 2>&1
    echo "restarted omarchy-shell"
  fi
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
