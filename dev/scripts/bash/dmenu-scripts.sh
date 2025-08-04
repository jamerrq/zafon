#!/usr/bin/env bash

SCRIPT_DIR=~/dev/scripts/bash
ICON=~/pictures/nikki/icons/nikki_random.png

# Si ROFI_RETV no existe o es igual a 0, solo imprime la lista de scripts
if [ -z "$ROFI_RETV" ] || [ "$ROFI_RETV" -eq 0 ]; then
    ls "$SCRIPT_DIR"
    exit 0
fi

# Si ROFI_RETV es 1 (algo fue seleccionado), $1 tiene el valor seleccionado
chosen="$1"

# Si no se eligió nada, salimos
[ -z "$chosen" ] && exit 0

# Lanzamos notificación y ejecutamos el script
notify-send -i "$ICON" "Running $chosen..." "Your script is launching 󱓞 "
bash "$SCRIPT_DIR/$chosen"
