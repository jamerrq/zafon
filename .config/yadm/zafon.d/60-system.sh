#!/bin/bash
# zafon:name=System (sudo)
# zafon:desc=root-owned units, e.g. the ACPI wakeup fix
# zafon:optional=true

set -uo pipefail

INSTALLER="$HOME/.config/yadm/system/install.sh"
WAKEUP_BIN=/usr/local/bin/disable-acpi-wakeup
WAKEUP_UNIT=disable-acpi-wakeup.service
SLEEP_HOOK=/etc/systemd/system-sleep/disable-acpi-wakeup
LEGACY_TMPFILES=/etc/tmpfiles.d/acpi-wakeup.conf

check() {
  local problems=()

  [[ -x $WAKEUP_BIN ]] || problems+=("$WAKEUP_BIN not installed")
  [[ -x $SLEEP_HOOK ]] || problems+=("$SLEEP_HOOK not installed")
  [[ ! -e $LEGACY_TMPFILES ]] || problems+=("legacy $LEGACY_TMPFILES still present")

  if systemctl list-unit-files "$WAKEUP_UNIT" >/dev/null 2>&1 &&
     systemctl is-enabled "$WAKEUP_UNIT" >/dev/null 2>&1; then
    :
  else
    problems+=("$WAKEUP_UNIT not enabled")
  fi

  if ((${#problems[@]})); then
    printf '%s\n' "${problems[@]}"
    return 2
  fi

  # Report anything still armed. /proc/acpi/wakeup resets every boot, so a
  # device showing *enabled here means the unit did not run or did not cover it.
  local still=()
  local dev
  for dev in XHCI RP09 RP10 RP05 AWAC; do
    grep -q "^${dev}[[:space:]].*\*enabled" /proc/acpi/wakeup 2>/dev/null && still+=("$dev")
  done
  if ((${#still[@]})); then
    echo "unit enabled but still armed: ${still[*]}"
    return 1
  fi

  # The ACPI toggle is not enough: on resume ACPI re-arms the GPE of every
  # device whose generic wake capability is still enabled. Check the capability
  # itself, otherwise this reports green while the next suspend wakes at once.
  local file
  for file in /sys/bus/pci/drivers/xhci_hcd/*/power/wakeup /sys/bus/usb/devices/*/power/wakeup; do
    [[ -e $file ]] || continue
    [[ $(cat "$file") == enabled ]] && still+=("${file#/sys/}")
  done
  if ((${#still[@]})); then
    echo "wake capability still enabled: ${still[*]}"
    return 1
  fi

  echo "acpi/usb wakeup fix installed and applied"
  return 0
}

apply() {
  if [[ ! -x $INSTALLER ]]; then
    echo "installer not found at $INSTALLER" >&2
    return 1
  fi
  # Prompts for sudo. Kept out of --yes runs by the optional flag.
  "$INSTALLER"
}

case "${1:-check}" in
  check) check ;;
  apply) apply ;;
  *) echo "usage: $(basename "$0") {check|apply}" >&2; exit 3 ;;
esac
