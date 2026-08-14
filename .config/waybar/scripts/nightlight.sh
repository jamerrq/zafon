#!/bin/bash

ON_TEMP=4000
OFF_TEMP=6000

# Check if hyprsunset is running
if ! pgrep -x hyprsunset > /dev/null; then
  echo '{"text": ""}'
  exit 0
fi

# Query the current temperature
CURRENT_TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')

if [[ -z $CURRENT_TEMP ]]; then
  echo '{"text": ""}'
  exit 0
fi

if [[ $CURRENT_TEMP == $OFF_TEMP ]]; then
  echo '{"text": ""}'
else
  echo '{"text": " 󰽥", "tooltip": "Night light active", "class": "active"}'
fi
