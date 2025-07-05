#!/usr/bin/env bash

ICON_DIR=~/pictures/icons
ICONS=("stinkfly.png" "cannonball.png" "ripjaws.png")
ICON="$ICON_DIR/${ICONS[RANDOM % ${#ICONS[@]}]}"

WALL_DIR=~/pictures/wallpapers
WALL=$(find "$WALL_DIR" -type f | shuf -n 1)

notify-send -i "$ICON" "locking..." "screen will be locked"

betterlockscreen -u "$WALL" --fx blur,dim

lock_and_then() {
    betterlockscreen -l &
    sleep 1
    dunstctl close-all

    case "$1" in
        suspend)
            systemctl suspend
            ;;
        hibernate)
            systemctl hibernate
            ;;
        "")
            ;;
        *)
            notify-send -u critical "⚠️ unknown option: $1"
            ;;
    esac
}

# --- Lógica de entrada ---
case "$1" in
    --suspend)
        lock_and_then suspend
        ;;
    --hibernate)
        lock_and_then hibernate
        ;;
    "" | --lock)
        lock_and_then
        ;;
    *)
        echo "Usage: $0 [--lock] [--suspend] [--hibernate]"
        exit 1
        ;;
esac
