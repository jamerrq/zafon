#!/usr/bin/env bash
# Force kill the active Hyprland window (SIGKILL)
# Useful for frozen/unresponsive apps where SUPER+W (killactive) doesn't work

PID=$(hyprctl activewindow -j | jq -r '.pid')

if [[ -n "$PID" && "$PID" != "null" && "$PID" -gt 0 ]]; then
    kill -9 "$PID"
fi
