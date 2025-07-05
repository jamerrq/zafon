#!/usr/bin/env bash

# Detect workspace actual
ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

# Layout JSON
LAYOUT=~/.config/i3/layouts/spotify.json
ICON=~/pictures/icons/ultra-t.png

# Aplica layout al workspace actual
i3-msg "workspace $ws; append_layout $LAYOUT"

# Notifica el inicio
notify-send -i "$ICON" "🎵 Spotify layout" "Running layout on workspace $ws"

# Lanzar Spotify
spotify &

# Esperar para que aparezca
sleep 2

# Lanzar cava en terminal
kitty -e cava &


