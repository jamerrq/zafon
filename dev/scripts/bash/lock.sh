#!/usr/bin/env bash

ICON_DIR=~/pictures/nikki/icons
ICONS=("nikki_sleepy.png" "nikki_deep_sleep.png")
ICON="$ICON_DIR/${ICONS[RANDOM % ${#ICONS[@]}]}"

WALL_DIR=~/pictures/wallpapers
WALL=/home/jamerrq/pictures/wallpapers/nikki.jpg


lock_and_then() {
    case "$1" in
        suspend)
            notify-send -i "$ICON" "suspending..." -t 3000
            ;;
        hibernate)
            notify-send -i "$ICON" "hibernating..." -t 3000
            ;;
        reboot)
            notify-send -i "$ICON" "rebooting..." -t 3000
            ;;
        shutdown)
            notify-send -i "$ICON" "shutting down..." -t 3000
            ;;
        "")
            notify-send -i "$ICON" "locking..." -t 3000
            ;;
        *)
            notify-send -u critical "⚠️ unknown option: $1"
            ;;
    esac

    # swaylock -f -i "$WALL" -k -l -e -F
    swaylock \
        --screenshots \
        --clock \
        --indicator \
        --indicator-radius 100 \
        --indicator-thickness 7 \
        --effect-blur 7x5 \
        --effect-vignette 0.5:0.5 \
        --ring-color 1F4E5F \
        --key-hl-color 79A8A9 \
        --line-color 00000000 \
        --inside-color 00000088 \
        --separator-color 00000000 \
        --grace 2 \
        --fade-in 0.2swaylock -l --fade-in 5 --screenshot --effect-pixelate 10 --effect-greyscale --clock --indicator \
        --font "ShureTechMono Nerd Font" \
        --text-color F4F7F7 &
    sleep 1
    # dunstctl close-all
    # makoctl dismiss -a

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
        echo "usage: $0 [--lock] [--suspend] [--hibernate] [--reboot] [--shutdown]"
        exit 1
        ;;
esac
