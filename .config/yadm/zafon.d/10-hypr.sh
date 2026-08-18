#!/bin/bash
# zafon:name=Hyprland
# zafon:desc=nikki.conf sourced from hyprland.conf, keybound helper scripts

set -uo pipefail

HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
NIKKI_CONF="$HOME/.config/hypr/nikki.conf"
SOURCE_LINE="source = ~/.config/hypr/nikki.conf"
SCRIPTS_DIR="$HOME/.config/yadm/scripts"

# Helper scripts bound to keys in nikki.conf. If any is missing or not
# executable the binding fails silently at press time, which is hard to notice.
SCRIPTS=(force-kill-active.sh launch-pop-terminal.sh restart-active.sh toggle-bluetooth.sh)

check() {
  local problems=()

  [[ -f $NIKKI_CONF ]] || { echo "nikki.conf is missing (pull it from yadm)"; return 2; }
  [[ -f $HYPRLAND_CONF ]] || { echo "hyprland.conf is missing"; return 2; }

  grep -qF "$SOURCE_LINE" "$HYPRLAND_CONF" || problems+=("hyprland.conf does not source nikki.conf")

  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ ! -f $SCRIPTS_DIR/$s ]]; then
      problems+=("missing script: $s")
    elif [[ ! -x $SCRIPTS_DIR/$s ]]; then
      problems+=("not executable: $s")
    fi
  done

  # The brightness binds must call the script directly: the `omarchy` dispatcher
  # execs by absolute path into its own bin dir and ignores our PATH override.
  if grep -q "exec, omarchy brightness display" "$NIKKI_CONF" 2>/dev/null; then
    problems+=("brightness binds go through the dispatcher, bypassing ~/.local/bin")
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "nikki.conf sourced, ${#SCRIPTS[@]} helper scripts present"
  return 0
}

apply() {
  if [[ ! -f $NIKKI_CONF ]]; then
    echo "cannot apply: nikki.conf is missing, restore it with yadm first" >&2
    return 1
  fi

  if ! grep -qF "$SOURCE_LINE" "$HYPRLAND_CONF"; then
    printf '\n%s\n' "$SOURCE_LINE" >>"$HYPRLAND_CONF"
    echo "added nikki.conf source line to hyprland.conf"
  fi

  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ -f $SCRIPTS_DIR/$s && ! -x $SCRIPTS_DIR/$s ]]; then
      chmod +x "$SCRIPTS_DIR/$s"
      echo "made executable: $s"
    fi
  done

  hyprctl reload >/dev/null 2>&1 && echo "reloaded hyprland"
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
