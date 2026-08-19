#!/bin/bash
# zafon:name=Omarchy overrides
# zafon:desc=patched scripts shadowing ~/.local/share/omarchy/bin via ~/.local/bin

set -uo pipefail

SRC_DIR="$HOME/.config/yadm/omarchy/bin"
DEST_DIR="$HOME/.local/bin"
OMARCHY_BIN="$HOME/.local/share/omarchy/bin"
ENV_DROPIN="$HOME/.config/environment.d/10-zafon-path.conf"
UWSM_ENV="$HOME/.config/uwsm/env"

SCRIPTS=(omarchy-brightness-display omarchy-toggle-nightlight omarchy-audio-output-switch)

check() {
  local problems=()

  [[ -d $SRC_DIR ]] || { echo "$SRC_DIR is missing (pull it from yadm)"; return 2; }

  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ ! -e $DEST_DIR/$s ]]; then
      problems+=("not installed: $s")
    elif [[ $(readlink -f "$DEST_DIR/$s") != "$(readlink -f "$SRC_DIR/$s")" ]]; then
      problems+=("$s does not point at the yadm copy")
    fi
  done

  [[ -f $ENV_DROPIN ]] || problems+=("environment.d PATH drop-in is missing")

  # uwsm is what actually decides the session PATH under Omarchy: it sources
  # this file and pushes the result into the systemd user manager after the
  # environment.d generators have run, overwriting their PATH entirely.
  if [[ -f $UWSM_ENV ]]; then
    grep -q 'PATH=$HOME/.local/bin' "$UWSM_ENV" ||
      problems+=("$UWSM_ENV does not prepend ~/.local/bin (it overrides environment.d)")
  fi

  # The systemd user manager reads environment.d only at session start, so the
  # running session can be correct on disk yet still resolve the wrong binary.
  # The systemd user manager reads environment.d only at session start, so the
  # running session can be correct on disk yet still resolve the wrong binary.
  local live_path
  live_path=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^PATH=//p')
  if [[ -n $live_path ]]; then
    local -i idx=0 ours=-1 theirs=-1
    local entry
    while IFS= read -r entry; do
      [[ $entry == "$DEST_DIR" && $ours -lt 0 ]] && ours=$idx
      [[ ${entry%/} == "${OMARCHY_BIN%/}" && $theirs -lt 0 ]] && theirs=$idx
      ((idx++))
    done < <(printf '%s' "$live_path" | tr ':' '\n')

    if ((ours < 0)); then
      problems+=("~/.local/bin not on the session PATH yet -- relaunch Hyprland to pick it up")
    elif ((theirs >= 0 && ours > theirs)); then
      problems+=("~/.local/bin is on the session PATH but after omarchy's bin")
    fi
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "${#SCRIPTS[@]} overrides installed and ahead of omarchy on PATH"
  return 0
}

apply() {
  mkdir -p "$DEST_DIR"

  local s
  for s in "${SCRIPTS[@]}"; do
    if [[ ! -f $SRC_DIR/$s ]]; then
      echo "skipping $s: not in yadm" >&2
      continue
    fi
    chmod +x "$SRC_DIR/$s"
    ln -sfn "$SRC_DIR/$s" "$DEST_DIR/$s"
    echo "linked: $s"
  done

  if [[ ! -f $ENV_DROPIN ]]; then
    echo "warning: $ENV_DROPIN is missing; restore it from yadm" >&2
  fi

  # Nothing here can affect already-running processes: environment.d is read
  # once, when the systemd user manager starts.
  if ! systemctl --user show-environment 2>/dev/null | grep -q "^PATH=.*$DEST_DIR"; then
    echo "note: relaunch Hyprland for its child processes to pick this up"
  fi
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
