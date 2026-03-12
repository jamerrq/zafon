#!/bin/bash
if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
    notify-send "󰂲 Bluetooth" "Apagado"  # Opcional, si quieres notificación
else
    bluetoothctl power on
    notify-send "󰂯 Bluetooth" "Encendido"
fi
