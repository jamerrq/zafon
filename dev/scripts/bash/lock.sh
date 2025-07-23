#!/usr/bin/env bash

ICON_DIR=~/pictures/icons
ICONS=("stinkfly.png" "cannonball.png" "ripjaws.png")
ICON="$ICON_DIR/${ICONS[RANDOM % ${#ICONS[@]}]}"

WALL_DIR=~/pictures/wallpapers
WALL=$(find "$WALL_DIR" -type f | shuf -n 1)


lock_and_then() {
    case "$1" in
        suspend)
            notify-send -i "$ICON" "suspending..."
            ;;
        hibernate)
            notify-send -i "$ICON" "hibernating..."
            ;;
        reboot)
            notify-send -i "$ICON" "rebooting..."
            ;;
        shutdown)
            notify-send -i "$ICON" "shutting down..."
            ;;
        "")
            notify-send -i "$ICON" "locking..."
            ;;
        *)
            notify-send -u critical "⚠️ unknown option: $1"
            ;;
    esac

    betterlockscreen -u "$WALL" --fx blur,dim
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
        reboot)
            systemctl reboot
            ;;
        shutdown)
            systemctl poweroff
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
    --reboot)
        lock_and_then reboot
        ;;
    --shutdown)
        lock_and_then shutdown
        ;;
    "" | --lock)
        lock_and_then
        ;;
    *)
        echo "Usage: $0 [--lock] [--suspend] [--hibernate] [--reboot] [--shutdown]"
        exit 1
        ;;
esac
