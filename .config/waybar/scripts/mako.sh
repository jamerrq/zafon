#!/bin/bash

# File: ~/.config/waybar/mako.sh
# Make sure it's executable: chmod +x ~/.config/waybar/mako.sh

# Handle click events from Waybar
if [[ "$1" == "toggle" ]]; then
  makoctl mode -t do-not-disturb
  if makoctl mode | grep -q 'do-not-disturb'; then
    notify-send "Silenced notifications"
  else
    notify-send "Enabled notifications"
  fi
fi

# Get current mode (take only the last line to avoid multiple modes)
CURRENT_MODE=$(makoctl mode | tail -n 1)

# Determine icon and class based on mode
if [[ "$CURRENT_MODE" == "do-not-disturb" ]]; then
  ICON=""
  CLASS="notifications-silenced"
else
  ICON=""
  CLASS="notifications-enabled"
fi

# Output JSON for Waybar
echo "{\"text\": \"$ICON\", \"class\": \"$CLASS\", \"tooltip\": \"Notifications: $CURRENT_MODE\"}"
