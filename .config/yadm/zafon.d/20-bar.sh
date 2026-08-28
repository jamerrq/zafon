#!/bin/bash
# zafon:name=Bar
# zafon:desc=Arch logo on the shell bar in place of the Omarchy one

# Replaces the old 20-waybar.sh. Quattro dropped waybar entirely -- the bar is
# now a Quickshell plugin inside omarchy-shell, configured from shell.json.
#
# The Arch logo is a custom user QML module rather than a clone of the built-in
# omarchy.menu plugin. Cloning that would fork its 54KB Menu.qml just to change
# one glyph and freeze the menu at the cloned version; a custom module replaces
# only the button, so the menu itself keeps getting upstream updates.

set -uo pipefail

MODULE="$HOME/.config/omarchy/bar/modules/arch.qml"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
# U+F08C7, nf-md-arch. Matched by codepoint so a mangled glyph is caught.
GLYPH_CODEPOINT="0xF08C7"

check() {
  local problems=()

  [[ -f $SHELL_JSON ]] || { echo "shell.json is missing"; return 2; }

  if ! jq -e . "$SHELL_JSON" >/dev/null 2>&1; then
    echo "shell.json is not valid JSON"
    return 2
  fi

  if [[ ! -f $MODULE ]]; then
    problems+=("arch.qml module is missing (pull it from yadm)")
  else
    grep -qF "$GLYPH_CODEPOINT" "$MODULE" ||
      problems+=("arch.qml no longer uses the $GLYPH_CODEPOINT Arch glyph")
  fi

  # The module only renders if the bar layout actually references it. Any
  # section will do -- the bar gestures can move it off the left.
  jq -e '[.bar.layout[]?[]? | select(.id == "arch" and .type == "qml")] | length > 0' \
    "$SHELL_JSON" >/dev/null 2>&1 ||
    problems+=("shell.json does not place the 'arch' qml module on the bar")

  jq -e '[.bar.layout[]?[]? | select(.id == "omarchy.menu")] | length == 0' \
    "$SHELL_JSON" >/dev/null 2>&1 ||
    problems+=("shell.json still shows the stock omarchy.menu logo button")

  pgrep -f "quickshell.*omarchy/shell" >/dev/null 2>&1 ||
    problems+=("omarchy-shell is not running")

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "Arch logo module in place and on the bar"
  return 0
}

apply() {
  if [[ ! -f $MODULE ]]; then
    echo "cannot apply: $MODULE is missing, restore it with:" >&2
    echo "  yadm checkout -- .config/omarchy/bar/modules/arch.qml" >&2
    return 1
  fi

  # Swap the stock menu button for the arch module in place, preserving its
  # position in whichever section it currently sits in.
  local tmp
  tmp=$(mktemp)
  if jq '.bar.layout |= with_entries(.value |= map(
          if .id == "omarchy.menu" then {id: "arch", type: "qml"} else . end))' \
       "$SHELL_JSON" >"$tmp" 2>/dev/null && [[ -s $tmp ]]; then
    if ! cmp -s "$tmp" "$SHELL_JSON"; then
      cat "$tmp" >"$SHELL_JSON"
      echo "pointed the bar at the arch module"
    fi
  else
    rm -f "$tmp"
    echo "failed to rewrite shell.json" >&2
    return 1
  fi
  rm -f "$tmp"

  # shell.json hot-reloads, but a new/edited QML module needs the shell back.
  if command -v omarchy-restart-shell >/dev/null 2>&1; then
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
