#!/usr/bin/env bash
# Restart the active Hyprland window
# Captures the process argv and cwd, stops it (and its helper processes),
# waits until everything is really gone, then relaunches it.
#
# Usage: restart-active.sh [pid]   (pid defaults to the active window's)

if [[ -n "$1" ]]; then
    PID=$1
    CLASS=$(ps -o comm= -p "$PID")
else
    WINDOW_JSON=$(hyprctl activewindow -j)
    PID=$(jq -r '.pid' <<<"$WINDOW_JSON")
    CLASS=$(jq -r '.class // "Unknown"' <<<"$WINDOW_JSON")
fi

if [[ -z "$PID" || "$PID" == "null" || "$PID" -le 0 || ! -d /proc/$PID ]]; then
    notify-send "Restart" "No active window found"
    exit 1
fi

# Read argv as a real array so arguments with spaces survive
mapfile -d '' -t ARGV </proc/"$PID"/cmdline
if (( ${#ARGV[@]} == 0 )); then
    notify-send "Restart" "Could not determine command for PID $PID"
    exit 1
fi

CWD=$(readlink /proc/"$PID"/cwd 2>/dev/null)

# Every descendant (Chromium/Electron zygotes, renderers, native hosts...).
# Relaunching while these still hold the profile makes the new instance hand
# off to the dying one and exit, which looks like "it only got killed".
descendants() {
    local child
    for child in $(pgrep -P "$1"); do
        echo "$child"
        descendants "$child"
    done
}
PIDS=("$PID" $(descendants "$PID"))

alive() {
    local p
    for p in "${PIDS[@]}"; do
        kill -0 "$p" 2>/dev/null && return 0
    done
    return 1
}

notify-send "Restart" "Restarting $CLASS..."

# Graceful first, so browsers save their session instead of showing
# "restore pages?"; SIGKILL whatever is still around after 5s.
kill -TERM "$PID" 2>/dev/null
for _ in {1..50}; do
    alive || break
    sleep 0.1
done
if alive; then
    kill -KILL "${PIDS[@]}" 2>/dev/null
    for _ in {1..20}; do
        alive || break
        sleep 0.1
    done
fi

# Relaunch the way Omarchy launches apps: own systemd scope via uwsm-app,
# detached from this script.
[[ -n "$CWD" && -d "$CWD" ]] && cd "$CWD"
if command -v uwsm-app >/dev/null; then
    setsid -f uwsm-app -- "${ARGV[@]}" >/dev/null 2>&1
else
    setsid -f "${ARGV[@]}" >/dev/null 2>&1
fi
