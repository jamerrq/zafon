#!/bin/bash
# zafon:name=Waybar
# zafon:desc=config, style and custom scripts (yadm is the source of truth)

set -uo pipefail

CONFIG="$HOME/.config/waybar/config.jsonc"
STYLE="$HOME/.config/waybar/style.css"
NIGHTLIGHT="$HOME/.config/waybar/scripts/nightlight.sh"
SPOTIFY="$HOME/.config/waybar/spotify.sh"

TRACKED=(
  .config/waybar/config.jsonc
  .config/waybar/style.css
  .config/waybar/spotify.sh
  .config/waybar/scripts/nightlight.sh
)

check() {
  local problems=()

  [[ -f $CONFIG ]] || { echo "config.jsonc is missing (pull it from yadm)"; return 2; }
  [[ -f $STYLE ]] || problems+=("style.css is missing")

  # These are the customizations omarchy-refresh-waybar used to destroy.
  grep -q "󰣇" "$CONFIG" || problems+=("Arch logo missing from config.jsonc")
  grep -q "custom/nightlight" "$CONFIG" || problems+=("nightlight module missing")
  grep -q "custom/spotify" "$CONFIG" || problems+=("spotify module missing")
  grep -q "FiraCode" "$STYLE" 2>/dev/null || problems+=("style.css is not using FiraCode")

  # A hardcoded /home/<user>/ path here breaks on any other machine.
  if grep -q '"exec": "/home/' "$CONFIG"; then
    problems+=("config.jsonc has a hardcoded /home/... exec path")
  fi

  local f
  for f in "$NIGHTLIGHT" "$SPOTIFY"; do
    [[ -f $f ]] || problems+=("missing script: ${f##*/}")
    [[ -f $f && ! -x $f ]] && problems+=("not executable: ${f##*/}")
  done

  # Drift against the repo. Anything that rewrote these files behind our back
  # shows up here rather than silently persisting.
  local dirty
  dirty=$(yadm diff --name-only -- "${TRACKED[@]}" 2>/dev/null)
  [[ -n $dirty ]] && problems+=("differs from yadm: $(echo "$dirty" | tr '\n' ' ')")

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "config, style and 2 scripts match yadm"
  return 0
}

apply() {
  # yadm holds the canonical copy, so restoring is a checkout rather than a
  # sequence of seds against whatever omarchy last wrote.
  if ! yadm checkout -- "${TRACKED[@]}" 2>/dev/null; then
    echo "yadm checkout failed; are the waybar files committed?" >&2
    return 1
  fi
  echo "restored waybar files from yadm"

  chmod +x "$NIGHTLIGHT" "$SPOTIFY" 2>/dev/null

  if command -v omarchy-restart-waybar >/dev/null 2>&1; then
    omarchy-restart-waybar >/dev/null 2>&1
    echo "restarted waybar"
  fi
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
