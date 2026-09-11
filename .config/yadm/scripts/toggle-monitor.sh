#!/bin/bash

# Toggle a monitor on or off, persistently, with a notification.
#
# The bar's Display widget is supposed to do this and cannot: it still shells
# out to `hyprctl keyword`, which Hyprland's Lua config parser rejects outright
# ("keyword can't work with non-legacy parsers. Use eval."), and the panel
# throws the exit code away, so a click silently does nothing in either
# direction. Upstream bug omacom/omarchy#6968, unfixed as of 4.0.0.alpha.
#
# Even once that lands, a widget toggle is a runtime rule that the next config
# reload drops -- hypr/monitors.lua's catch-all `output = ""` rule turns the
# output straight back on. So state lives in a toggle flag file that
# default/hypr/toggles auto-requires on every reload, the same machinery
# Omarchy uses for internal-monitor-disable.lua. See the Monitors section of
# hypr/zafon.lua for why the mode line there carries no `disabled` key.

set -uo pipefail

monitor="${1:-HDMI-A-2}"

# The name is interpolated into an eval'd Lua string below, so only a plain
# connector name may pass -- same guard the bin/ monitor helpers use.
if [[ ! $monitor =~ ^[A-Za-z0-9._-]+$ ]]; then
  notify-send -u critical "󰍹  Monitor" "Invalid output name: $monitor"
  exit 1
fi

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
toggles_dir="$state_home/omarchy/toggles/hypr"
# Lowercased so the filename matches the sorted-require order predictably.
flag="$toggles_dir/${monitor,,}-disabled.lua"

if ! mkdir -p "$toggles_dir"; then
  notify-send -u critical "󰍹  Monitor" "Unable to write $toggles_dir"
  exit 1
fi

# Ask Hyprland rather than trusting the flag: the two can disagree if someone
# ran hyprctl by hand since the last reload.
#
# Presence and value are read separately on purpose. `.disabled // empty` looks
# like the natural way to do both at once, but jq's // yields the right-hand
# side when the left is *false* as well as null, so an enabled monitor reads as
# absent and this bails with "is not connected" on the one path that matters.
monitor_info="$(hyprctl monitors all -j | jq -c --arg m "$monitor" \
  '[.[] | select(.name == $m)][0]')"

if [[ -z $monitor_info || $monitor_info == "null" ]]; then
  notify-send -u critical "󰍹  Monitor" "$monitor is not connected"
  exit 1
fi

is_disabled="$(jq -r '.disabled' <<<"$monitor_info")"

if [[ $is_disabled == "true" ]]; then
  # Turning it on: drop the flag, then re-enable live so the change lands
  # without waiting for a reload. `disabled = false` is load-bearing -- omit it
  # and hl.monitor merges into the existing disable, answers ok, stays dark.
  rm -f "$flag"
  if ! hyprctl eval "hl.monitor({ output = \"$monitor\", disabled = false })" >/dev/null; then
    notify-send -u critical "󰍹  Monitor" "Unable to turn on $monitor"
    exit 1
  fi
  # Reload to re-apply mode/position/scale from zafon.lua on top.
  hyprctl reload >/dev/null
else
  cat >"$flag" <<LUA
-- Written by yadm/scripts/toggle-monitor.sh. Remove this file, or press
-- SUPER + ALT + U, to bring $monitor back. See hypr/zafon.lua.
hl.monitor({ output = "$monitor", disabled = true })
LUA
  if ! hyprctl eval "hl.monitor({ output = \"$monitor\", disabled = true })" >/dev/null; then
    rm -f "$flag"
    notify-send -u critical "󰍹  Monitor" "Unable to turn off $monitor"
    exit 1
  fi
fi

# Report what actually happened rather than what we asked for.
if [[ "$(hyprctl monitors all -j | jq -r --arg m "$monitor" \
  '[.[] | select(.name == $m)][0].disabled')" == "true" ]]; then
  notify-send "󰶐  Monitor" "$monitor turned off"
else
  notify-send "󰍹  Monitor" "$monitor turned on"
fi
