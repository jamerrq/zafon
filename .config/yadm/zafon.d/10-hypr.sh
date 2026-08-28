#!/bin/bash
# zafon:name=Hyprland
# zafon:desc=personal Lua overrides (borders, latam, monitors, binds) + helper scripts

# Quattro moved Hyprland from hyprland.conf to hyprland.lua. nikki.conf's
# successor is hypr/zafon.lua, a single file holding every personal setting,
# required last from hyprland.lua so it overrides both Omarchy's defaults and
# the stock per-topic files.
#
# Because the per-topic files stay stock, `omarchy refresh config
# hypr/<topic>.lua` can reset any of them without touching personal config --
# so this module only has one file to watch.
#
# The greps below only prove the config still SAYS the right thing. The hyprctl
# checks prove Hyprland actually took it -- a Lua error can leave the file
# intact while the running compositor falls back to defaults.

set -uo pipefail

HYPR_DIR="$HOME/.config/hypr"
SCRIPTS_DIR="$HOME/.config/yadm/scripts"
ZAFON_LUA="$HOME/.config/hypr/zafon.lua"

# Helper scripts bound to keys in zafon.lua. If any is missing or not
# executable the binding fails silently at press time, which is hard to notice.
SCRIPTS=(force-kill-active.sh launch-pop-terminal.sh restart-active.sh toggle-bluetooth.sh)

# needle|label -- the personal overrides zafon.lua must still carry.
MARKERS=(
  "border_size = 4|thick borders"
  "rounding = 10|rounded corners"
  "allow_session_lock_restore = true|lock restore"
  "kb_layout = \"latam\"|latam keyboard"
  "HDMI-A-1|monitor layout"
  "Force kill active window|personal keybindings"
)

# option|expected -- what the running compositor must report.
LIVE=(
  "decoration:rounding|10"
  "general:border_size|4"
  "input:kb_layout|latam"
  "misc:allow_session_lock_restore|true"
)

hypr_running() { command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; }

getopt_value() {
  # hyprctl -j prints one of int/str/bool depending on the option's type.
  hyprctl getoption "$1" -j 2>/dev/null |
    sed -n 's/.*"\(int\|str\|bool\)": *"\?\([^",}]*\)"\?.*/\2/p' | head -n1
}

check() {
  local problems=()

  [[ -d $HYPR_DIR ]] || { echo "$HYPR_DIR is missing"; return 2; }

  local entry needle label
  if [[ ! -f $ZAFON_LUA ]]; then
    problems+=("zafon.lua is missing (pull it from yadm)")
  else
    for entry in "${MARKERS[@]}"; do
      IFS='|' read -r needle label <<<"$entry"
      grep -qF "$needle" "$ZAFON_LUA" || problems+=("zafon.lua lost the $label override")
    done
  fi

  # zafon.lua only takes effect if hyprland.lua actually pulls it in.
  grep -q 'require("hypr.zafon")' "$HYPR_DIR/hyprland.lua" 2>/dev/null ||
    problems+=("hyprland.lua does not require hypr.zafon")

  # A stray nikki.conf would be dead weight now -- nothing sources it, so
  # anything left in it is silently inert rather than applied.
  [[ -f $HYPR_DIR/nikki.conf ]] &&
    problems+=("nikki.conf still present but no longer loaded (port it or delete it)")

  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ ! -f $SCRIPTS_DIR/$s ]]; then
      problems+=("missing script: $s")
    elif [[ ! -x $SCRIPTS_DIR/$s ]]; then
      problems+=("not executable: $s")
    fi
  done

  if hypr_running; then
    local errs
    errs=$(hyprctl configerrors 2>/dev/null | grep -v '^[[:space:]]*$')
    [[ -n $errs ]] && problems+=("hyprctl reports config errors: ${errs//$'\n'/; }")

    local opt expected actual
    for entry in "${LIVE[@]}"; do
      IFS='|' read -r opt expected <<<"$entry"
      actual=$(getopt_value "$opt")
      [[ $actual == "$expected" ]] ||
        problems+=("live $opt is '${actual:-unknown}', expected '$expected'")
    done
  else
    problems+=("hyprland is not running, cannot verify the live config")
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "${#MARKERS[@]} zafon.lua overrides live, ${#SCRIPTS[@]} helper scripts present"
  return 0
}

apply() {
  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ -f $SCRIPTS_DIR/$s && ! -x $SCRIPTS_DIR/$s ]]; then
      chmod +x "$SCRIPTS_DIR/$s"
      echo "made executable: $s"
    fi
  done

  # Missing overrides are a content problem, not a state problem: restore the
  # Lua files from yadm rather than trying to re-synthesise them here.
  local entry needle label missing=0
  for entry in "${MARKERS[@]}"; do
    IFS='|' read -r needle label <<<"$entry"
    [[ -f $ZAFON_LUA ]] && grep -qF "$needle" "$ZAFON_LUA" || ((missing++))
  done
  if ((missing)); then
    echo "$missing override(s) missing from zafon.lua -- restore it with:" >&2
    echo "  yadm checkout -- .config/hypr/zafon.lua" >&2
    return 1
  fi

  if hypr_running; then
    hyprctl reload >/dev/null 2>&1 && echo "reloaded hyprland"
    local errs
    errs=$(hyprctl configerrors 2>/dev/null | grep -v '^[[:space:]]*$')
    if [[ -n $errs ]]; then
      echo "hyprland reloaded but reports errors:" >&2
      echo "$errs" >&2
      return 1
    fi
  fi
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
