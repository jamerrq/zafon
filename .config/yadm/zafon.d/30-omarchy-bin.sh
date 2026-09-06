#!/bin/bash
# zafon:name=Omarchy overrides
# zafon:desc=patched omarchy scripts shadowing /usr/bin via ~/.local/bin

# Quattro changed what we are competing with. Omarchy used to be a git checkout
# under ~/.local/share/omarchy with its bin/ prepended to PATH; now it is an
# Arch package that installs ~440 omarchy-* binaries straight into /usr/bin.
# So the directory our overrides must beat is /usr/bin, not omarchy's own bin.
#
# It also moved the session env file: ~/.config/uwsm/env became a directory of
# drop-ins, ~/.config/uwsm/env.d/*. That is still the only place the ordering
# can be fixed, because uwsm sources those and pushes the result into the
# systemd user manager AFTER the environment.d generators have run.

set -uo pipefail

SRC_DIR="$HOME/.config/yadm/omarchy/bin"
DEST_DIR="$HOME/.local/bin"
# Where the packaged omarchy binaries now live.
PACKAGED_DIR="/usr/bin"
UWSM_DROPIN="$HOME/.config/uwsm/env.d/99-zafon-path"
ZAFON_LUA="$HOME/.config/hypr/zafon.lua"
ENV_DROPIN="$HOME/.config/environment.d/10-zafon-path.conf"

# omarchy-brightness-display was dropped from this list in quattro. Upstream
# grew exactly the feature the patch existed for (external displays over DDC,
# via use_ddc_display -> omarchy-brightness-display-ddc), and the patched copy
# actively breaks the bar: the omarchy.monitor widget invokes it as
# `omarchy-brightness-display --no-osd --monitor <name> <N>%`, flags the old
# script does not parse -- it would read "--no-osd" as the step and exit 1.
# omarchy-toggle-nightlight was dropped too: quattro's copy is a strict
# superset (it grew --status, which the bar's indicator threshold pairs
# with) and the only thing the patched copy added was a
# `pkill -RTMIN+11 waybar` refresh for a bar that no longer exists.
# The binding is a stock default -- SUPER + CTRL + N.
SCRIPTS=(omarchy-audio-output-switch)

# Commands quattro removed. An override still calling one of these is silently
# degraded: the script runs, the feedback it tries to give never appears.
# This is the check that would have caught the brightness breakage early.
REMOVED_COMMANDS=(swayosd-client omarchy-swayosd-client waybar makoctl walker
                  omarchy-restart-walker omarchy-restart-waybar playerctl
                  hypridle hyprlock)

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

  # An override that calls a command quattro deleted still "works" enough to
  # look fine, so check the contents rather than just the symlink.
  local cmd
  for s in "${SCRIPTS[@]}"; do
    [[ -f $SRC_DIR/$s ]] || continue
    # Strip comments first: a script that merely *explains* why it stopped
    # calling a removed command must not be reported as still calling it.
    local code
    code=$(sed 's/#.*//' "$SRC_DIR/$s")
    for cmd in "${REMOVED_COMMANDS[@]}"; do
      grep -qE "(^|[^-[:alnum:]])${cmd}([^-[:alnum:]]|$)" <<<"$code" &&
        problems+=("$s calls '$cmd', which quattro removed")
    done
  done

  [[ -f $UWSM_DROPIN ]] || problems+=("uwsm env.d PATH drop-in is missing (${UWSM_DROPIN##*/})")

  # The session PATH is not what keybinds use. Omarchy's default/hypr/envs.lua
  # forces $OMARCHY_PATH/bin to the front of a separate PATH it hands every
  # dispatched process, so a bare-name binding runs the packaged copy however
  # the session PATH is ordered. hypr/zafon.lua re-asserts ~/.local/bin there,
  # and without that line every override is dead on its keybind while looking
  # perfectly installed here.
  grep -q 'hl.env("PATH"' "$ZAFON_LUA" 2>/dev/null ||
    problems+=("zafon.lua does not re-assert ~/.local/bin in the keybind dispatcher PATH")
  [[ -f $ENV_DROPIN ]] || problems+=("environment.d PATH drop-in is missing")

  # The systemd user manager reads its environment once, at session start, so
  # the drop-ins can be correct on disk while the running session still
  # resolves the packaged binary. Compare positions rather than trusting
  # `command -v`, which answers for this shell and not for the session.
  local live_path
  live_path=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^PATH=//p')
  if [[ -n $live_path ]]; then
    local -i idx=0 ours=-1 theirs=-1
    local entry
    while IFS= read -r entry; do
      [[ ${entry%/} == "${DEST_DIR%/}" && $ours -lt 0 ]] && ours=$idx
      [[ ${entry%/} == "${PACKAGED_DIR%/}" && $theirs -lt 0 ]] && theirs=$idx
      ((idx++))
    done < <(printf '%s' "$live_path" | tr ':' '\n')

    if ((ours < 0)); then
      problems+=("~/.local/bin not on the session PATH yet -- relaunch Hyprland to pick it up")
    elif ((theirs >= 0 && ours > theirs)); then
      problems+=("~/.local/bin is on the session PATH but after $PACKAGED_DIR -- relaunch Hyprland (note: this governs shells, not keybinds)")
    fi
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 1
  fi

  echo "${#SCRIPTS[@]} overrides installed, ahead on the session PATH and in the keybind dispatcher"
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

  if [[ ! -f $UWSM_DROPIN ]]; then
    mkdir -p "$(dirname "$UWSM_DROPIN")"
    cat >"$UWSM_DROPIN" <<'DROPIN'
# Put ~/.local/bin ahead of /usr/bin on the session PATH.
#
# Omarchy ships its omarchy-* scripts as an Arch package into /usr/bin, so
# editing them in place means the next package upgrade clobbers them. Patched
# copies live in yadm (~/.config/yadm/omarchy/bin) and are symlinked into
# ~/.local/bin, which wins by PATH precedence while the packaged copies stay
# pristine.
#
# This has to live here rather than in ~/.config/environment.d: uwsm sources
# env.d and pushes the result into the systemd user manager AFTER the
# environment.d generators run, overwriting whatever PATH they produced.
# The 99- prefix keeps it after Omarchy's own 10-omarchy drop-in.
#
# Changes require a relaunch of Hyprland to take effect.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
DROPIN
    echo "created ${UWSM_DROPIN##*/}"
  fi

  [[ -f $ENV_DROPIN ]] ||
    echo "warning: $ENV_DROPIN is missing; restore it from yadm" >&2

  # Nothing here can affect the running session: uwsm pushes PATH into the
  # systemd user manager once, when the session starts.
  local live_path
  live_path=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^PATH=//p')
  case ":${live_path}:" in
    *":${DEST_DIR}:"*) ;;
    *) echo "note: relaunch Hyprland for its child processes to pick this up" ;;
  esac
  return 0
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
