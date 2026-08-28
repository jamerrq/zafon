#!/bin/bash

# Toggle Bluetooth, with a notification.
#
# Quattro moved Bluetooth state onto the rfkill soft block (migration
# 1786380259): the block persists across reboots where BlueZ's Powered property
# does not, and systemd-rfkill restores it early at boot. The consequence for
# this script is that a plain `bluetoothctl power on` fails outright while the
# block is set -- and worse, while blocked `bluetoothctl show` prints no
# "Powered:" line at all, so the old grep never matched and this always took the
# "turn it on" branch, which then silently failed.
#
# omarchy-bluetooth-power is the one supported way in and out of that state. It
# gives no feedback of its own, which is what this wrapper is still here for.

set -uo pipefail

if ! command -v omarchy-bluetooth-power >/dev/null 2>&1; then
  notify-send -u critical "󰂲 Bluetooth" "omarchy-bluetooth-power no encontrado"
  exit 1
fi

if ! omarchy-bluetooth-power toggle; then
  notify-send -u critical "󰂲 Bluetooth" "No se pudo cambiar el estado"
  exit 1
fi

# Report what actually happened rather than what we asked for: turning the
# adapter on can still time out waiting for it to come up.
if omarchy-bluetooth-power is-on >/dev/null 2>&1; then
  notify-send "󰂯 Bluetooth" "Encendido"
else
  notify-send "󰂲 Bluetooth" "Apagado"
fi
