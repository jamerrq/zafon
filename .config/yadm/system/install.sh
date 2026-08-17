#!/bin/bash

# Installs the system-level (root-owned) pieces of the zafon setup.
#
# These live outside $HOME, so yadm cannot track them directly. The tracked
# sources live here in ~/.config/yadm/system/ and this script copies them into
# place. Re-running it is safe.

set -euo pipefail

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m'

if [[ $EUID -ne 0 ]]; then
  echo -e "${YELLOW}Re-running with sudo...${NC}"
  exec sudo -- "$0" "$@"
fi

# ACPI wakeup fix -------------------------------------------------------------
# /proc/acpi/wakeup resets to firmware defaults on every boot, so the fix has to
# be re-applied at each startup rather than set once.

install -m 755 "$SRC_DIR/disable-acpi-wakeup" /usr/local/bin/disable-acpi-wakeup
install -m 644 "$SRC_DIR/disable-acpi-wakeup.service" /etc/systemd/system/disable-acpi-wakeup.service

systemctl daemon-reload
systemctl enable --now disable-acpi-wakeup.service

echo -e "${GREEN}OK${NC}: disable-acpi-wakeup.service installed and enabled"
