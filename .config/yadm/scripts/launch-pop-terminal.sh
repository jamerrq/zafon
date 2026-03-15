#!/bin/bash

# Launch a floating, pinned ("popped") terminal window, similar to SUPER+O on an existing window.
# Assigns it a unique app-id so it can be identified and popped reliably.
# Window size defaults to half the active monitor's resolution.

APP_ID="org.omarchy.pop-terminal"

# Detect active monitor resolution and use half of it as default size
monitor_json=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
monitor_w=$(echo "$monitor_json" | jq '.width')
monitor_h=$(echo "$monitor_json" | jq '.height')
WIDTH=${1:-$((monitor_w / 2))}
HEIGHT=${2:-$((monitor_h / 2))}

# Launch the terminal as floating via Hyprland dispatch rule
hyprctl dispatch exec "[float; size $WIDTH $HEIGHT; center 1] uwsm-app -- xdg-terminal-exec --app-id=$APP_ID"

# Wait for the window to appear, then pin it and tag it as +pop
(
  for i in $(seq 1 20); do
    sleep 0.1
    addr=$(hyprctl clients -j | jq -r --arg id "$APP_ID" '.[] | select(.initialClass == $id or .class == $id) | .address' | head -1)
    if [[ -n "$addr" && "$addr" != "null" ]]; then
      hyprctl -q --batch \
        "dispatch pin address:$addr;" \
        "dispatch alterzorder top address:$addr;" \
        "dispatch tagwindow +pop address:$addr;"
      break
    fi
  done
) &
