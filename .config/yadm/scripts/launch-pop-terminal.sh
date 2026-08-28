#!/bin/bash

# Launch a floating, pinned ("popped") terminal, similar to SUPER+O on an
# existing window. It gets a unique app-id so a window rule can find it.
#
# Quattro rewrite. This used to place the window itself with
#   hyprctl dispatch exec "[float; size W H; center 1] ..."
# plus a polling loop that pinned and tagged the window once it appeared.
# Hyprland now parses `hyprctl dispatch` arguments as Lua, so the bracket-rule
# prefix is a syntax error:
#   error: ']' expected near ';'
#
# Rather than translate that into Lua, the placement moved to a real window rule
# in hypr/zafon.lua, keyed on the app-id below. The rule applies as the window
# maps, so the polling loop is gone too -- and there is no longer a window that
# briefly appears tiled before being pinned.

set -uo pipefail

APP_ID="org.omarchy.pop-terminal"

exec uwsm-app -- xdg-terminal-exec --app-id="$APP_ID"
