#!/bin/bash

# Script to toggle and display hypridle status in Waybar
# Save this file as ~/.config/waybar/hypridle.sh
# Make it executable: chmod +x ~/.config/waybar/hypridle.sh

# Handle click events from Waybar to toggle hypridle
if [[ "$1" == "toggle" ]]; then
  if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
    notify-send "Stop locking computer when idle"
  else
    uwsm app -- hypridle >/dev/null 2>&1 &
    notify-send "Now locking computer when idle"
  fi
fi

# Determine hypridle status
if pgrep -x hypridle >/dev/null; then
  ICON="👁️"
  CLASS="hypridle-active"
  TOOLTIP="hypridle is active (click to disable)"
else
  ICON="👁️‍🗨️"
  CLASS="hypridle-inactive"
  TOOLTIP="hypridle is inactive (click to enable)"
fi

# Output JSON for Waybar
echo "{\"text\": \"$ICON\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
