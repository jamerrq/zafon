#!/usr/bin/env bash
# Restart the active Hyprland window
# Captures the process command line, kills it, and relaunches it

WINDOW_JSON=$(hyprctl activewindow -j)
PID=$(echo "$WINDOW_JSON" | jq -r '.pid')

if [[ -z "$PID" || "$PID" == "null" || "$PID" -le 0 ]]; then
    notify-send "Restart" "No active window found"
    exit 1
fi

# Get the full command line used to launch the process
CMDLINE=$(cat /proc/"$PID"/cmdline 2>/dev/null | tr '\0' ' ' | sed 's/ $//')

if [[ -z "$CMDLINE" ]]; then
    notify-send "Restart" "Could not determine command for PID $PID"
    exit 1
fi

# Get the working directory of the original process
CWD=$(readlink /proc/"$PID"/cwd 2>/dev/null)

# Get the window class for the notification
CLASS=$(echo "$WINDOW_JSON" | jq -r '.class // "Unknown"')

# Kill the process
kill -9 "$PID"

# Wait briefly for the process to die
sleep 0.5

# Relaunch from the original working directory
notify-send "Restart" "Restarting $CLASS..."
if [[ -n "$CWD" && -d "$CWD" ]]; then
    cd "$CWD" && nohup $CMDLINE >/dev/null 2>&1 &
else
    nohup $CMDLINE >/dev/null 2>&1 &
fi
