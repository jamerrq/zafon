-- zafon.lua -- every personal Hyprland setting, in one file.
--
-- The successor to the pre-quattro nikki.conf. Quattro moved Hyprland from
-- hyprland.conf to hyprland.lua and split user overrides across
-- monitors/input/bindings/looknfeel.lua; this file collapses them back into a
-- single place, and hyprland.lua requires it last so it wins over all of them.
--
-- Keeping the per-topic files stock has a practical payoff: `omarchy refresh
-- config hypr/looknfeel.lua` (or any of the others) resets that file to the
-- packaged default without taking a single personal setting with it.
--
-- Checked by ~/.config/yadm/zafon.d/10-hypr.sh.

-- ---------------------------------------------------------------------------
-- Look and feel

-- Thick, rounded borders.
--
-- decoration.rounding does double duty: the Omarchy shell (Quickshell) mirrors
-- it into Style.cornerRadius, so this one value also rounds notifications, the
-- launcher and menu cards, and every bar flyout -- the job the old
-- mako.ini.tpl / walker.css.tpl border-radius used to do. Only the border
-- widths still need declaring, and those live in ~/.config/omarchy/shell.toml.
--
-- Omarchy ships its own corner modes (`omarchy hyprland corners rounded` ->
-- default/hypr/toggles/corners-rounded.lua, rounding = 6), but they only cover
-- the compositor side: the shell reads decoration:rounding from hyprctl, so
-- the rounded corners of the menus, notifications and indicators have to come
-- from this value. That is why the rounding stays here.
hl.config({
  general = {
    border_size = 4,
  },
  decoration = {
    rounding = 10,
  },
})

-- Translucent borders.
--
-- A border color takes an rgba() with the alpha as the trailing hex pair
-- (00 invisible, ff opaque); the theme's inactive border is already
-- rgba(595959aa), this only drops both further. Declaring col here overrides
-- the theme-generated ~/.local/state/omarchy/current/theme/hyprland.lua, so
-- the active color is pinned to the current theme's value and stops following
-- theme switches until this pair is re-read.
hl.config({
  general = {
    col = {
      active_border = "rgba(78824b00)",
      inactive_border = "rgba(59595900)",
    },
  },
})

-- Let hyprlock re-acquire the session lock after a crash instead of leaving
-- the desktop exposed.
hl.config({
  misc = {
    allow_session_lock_restore = true,
  },
})

-- ---------------------------------------------------------------------------
-- Input

hl.config({
  input = {
    kb_layout = "latam",
    -- Caps Lock acts as the Compose key.
    kb_options = "compose:caps",

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
  },
})

-- Keep the DualShock 4 touchpad from behaving as a mouse.
--
-- hid_playstation exposes the touchpad as its own input device, and libinput
-- classes it as a touchpad (it advertises BTN_TOUCH plus multitouch axes), so
-- brushing it with a thumb moves the pointer -- which games then read as mouse
-- look/aim. Nothing here needs it as a pointer, and the pad's touchpad button
-- still reaches the controller device itself, so the whole thing is disabled.
--
-- Name is Hyprland's slug for the kernel name "Sony Interactive Entertainment
-- Wireless Controller Touchpad". Note this is also what `omarchy-hw-touchpad`
-- reports on this machine, since there is no internal touchpad.
hl.device({ name = "sony-interactive-entertainment-wireless-controller-touchpad", enabled = false })

-- ---------------------------------------------------------------------------
-- Monitors
--
-- Scale is deliberately 1 on both: these are 1080p panels, nothing to scale up.
-- The matching omarchy_monitor_scale / omarchy_gdk_scale knobs are in
-- hypr/monitors.lua.
--
-- Refresh rates, read off `hyprctl monitors all -j | jq -r .[].availableModes[]`
-- rather than assumed: the LG really does list 1920x1080@100, the Samsung tops
-- out at 75 and prefers 60. An earlier version of this file pinned both to 100.
-- Hyprland accepts an unavailable rate silently -- it echoes the requested value
-- back in `hyprctl monitors` and raises nothing in `hyprctl configerrors` -- so
-- the Samsung appeared to run at 100Hz while it could not.

hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@100", position = "0x0", scale = 1 })

-- HDMI-A-2 deliberately carries no `disabled` key. Its on/off state lives in
-- ~/.local/state/omarchy/toggles/hypr/hdmi-a-2-disabled.lua, written and removed
-- by yadm/scripts/toggle-monitor.sh, bound to SUPER + ALT + U below.
--
-- That split is what makes the toggle survive a reload *and* a reboot.
-- hyprland.lua requires, in order: hypr/monitors.lua (:19, the catch-all
-- `output = ""` rule that enables every output), default/hypr/toggles (:26,
-- which auto-requires every *.lua in the state dir above), and finally this
-- file (:35). So the toggle file gets to decide on/off, and the line below only
-- ever supplies mode, position and scale.
--
-- It works because hl.monitor *edits* the rule for an output instead of
-- replacing it, so a spec that omits `disabled` leaves whatever the toggle set.
-- The same merge is a trap in the other direction: re-enabling an output
-- without an explicit `disabled = false` answers `ok` and leaves it dark, which
-- is why the script always passes the key.
--
-- None of this can go through the bar's Display widget. That widget still
-- shells out to `hyprctl keyword`, which the Lua config parser rejects outright
-- ("keyword can't work with non-legacy parsers. Use eval.") while the panel
-- discards the exit code -- so clicking a display row silently does nothing, in
-- both directions. Upstream: omacom/omarchy#6968, unfixed as of 4.0.0.alpha.
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@75", position = "1920x0", scale = 1 })

-- ---------------------------------------------------------------------------
-- Bindings
--
-- Nothing here unbinds an Omarchy default. Where a key was already taken, the
-- personal binding moved to a free chord instead of displacing the stock one,
-- so `omarchy menu keybindings --print` stays an accurate picture of what the
-- system does.
--
-- To find a free chord, grep the printed list -- the short form still works:
--   omarchy-menu-keybindings -p | grep -i 'suspend'

local home = os.getenv("HOME")
local scripts = home .. "/.config/yadm/scripts"

-- Put ~/.local/bin first in the PATH that keybinds inherit.
--
-- Omarchy's default/hypr/envs.lua ends with a loop that forces
-- $OMARCHY_PATH/bin to position 1 of the dispatcher PATH and pushes it through
-- hl.env. That env is separate from Hyprland's own: /proc/<hyprland>/environ
-- can have ~/.local/bin first (uwsm/env.d/99-zafon-path puts it there) while a
-- dispatched process still resolves /usr/share/omarchy/bin -- which is exactly
-- why a bare-name binding ran the packaged omarchy-audio-output-switch instead
-- of the override, no matter what the session PATH said.
--
-- This file is required last, so re-asserting here wins. Same idiom as the
-- loop it is correcting, just with a different directory in front.
local local_bin = home .. "/.local/bin"
local path_entries = {}
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
  if entry ~= local_bin then table.insert(path_entries, entry) end
end
table.insert(path_entries, 1, local_bin)
hl.env("PATH", table.concat(path_entries, ":"))

-- Suspend
o.bind("SUPER + CTRL + SHIFT + S", "Suspend", "systemctl suspend")

-- Media / extra keys.
o.bind("XF86HomePage", "Pop terminal", scripts .. "/launch-pop-terminal.sh")
-- The SUPER chord on that same key builds the Codeforces workspace instead:
-- statement, nvim and a run terminal, arranged by the "codeforces" layout near
-- the bottom of this file. SUPER + Home (restore window width) is an Omarchy
-- default and is deliberately left alone.
o.bind("SUPER + XF86HomePage", "Codeforces workspace", scripts .. "/cf-workspace.sh")
-- Was the browser, which already has SUPER + SHIFT + B. The envelope key now
-- opens the numbered games dock (~/.local/bin/game-dock): a floating foot
-- window listing only games, one number per game. Prism Launcher keeps its
-- SUPER + ALT + M binding below.
o.bind("XF86Mail", "Games dock", home .. "/.local/bin/game-dock")
o.bind("SUPER + XF86Calculator", "Toggle bluetooth", scripts .. "/toggle-bluetooth.sh")

-- Audio output switching has no binding here. Omarchy's own SHIFT + Mute is
-- left in place, and once the session picks up uwsm/env.d/99-zafon-path it
-- resolves omarchy-audio-output-switch to the ~/.local/bin override by PATH
-- precedence. Until that relaunch it runs the packaged copy, which cannot
-- switch a single-sink card.

-- Apps.
-- ALT + M for Minecraft; SUPER + P is Pseudo window and SUPER + SHIFT + P is
-- Google Photos, both stock. `focus` makes a second press raise the running
-- instance instead of starting a second launcher -- omarchy-launch-or-focus
-- matches the pattern against class OR title, and PrismLauncher is the
-- StartupWMClass from its .desktop file.
o.bind("SUPER + ALT + M", "Prism Launcher", { launch = "prismlauncher", focus = "PrismLauncher" })

-- Brightness has no binding on purpose: the bar's omarchy.monitor widget
-- covers it, and it drives the display over DDC without a keybind.

-- Monitors.
o.bind("SUPER + U", "Focus next monitor", hl.dsp.focus({ monitor = "+1" }))
-- hl.dsp.window.move has no monitor option (it accepts only direction,
-- x+y, workspace, into_group, out_of_group), so this one goes through
-- hyprctl to reach Hyprland's `movewindow mon:` form.
o.bind("SUPER + SHIFT + U", "Move window to next monitor", "hyprctl dispatch movewindow mon:+1")

-- Turn HDMI-A-2 off and on. Sits on the monitor family's spare chord: SUPER+U
-- focuses, SUPER+SHIFT+U moves, SUPER+ALT+U powers. The script takes the output
-- name as its first argument and defaults to HDMI-A-2.
o.bind("SUPER + ALT + U", "Toggle second monitor", scripts .. "/toggle-monitor.sh")

-- Pushing a workspace to the other monitor follows it there, mimicking i3.
--
-- This used to be hl.dsp.workspace.move({ monitor = "+1" }) plus a second bind
-- that focused the monitor. That raw dispatcher still moves the workspace, and
-- Hyprland carries focus along with it, so the second bind then resolved "+1"
-- from the monitor it had just arrived on: with two monitors that is the one it
-- left, and focus snapped straight back. The workspace looked like it had gone.
-- The raw move also leaves the workspace outside the target's block -- the bar
-- lists the first monitor's 1-10, the second's 11-20, and this arrived as a
-- guest the next reconcile would move again. o.workspaces.move_to_monitor
-- resolves the monitor, moves the workspace, renumbers it into that monitor's
-- block (3 -> 12, say), settles the monitor it left and focuses the moved
-- workspace. It is the action behind the stock SUPER + SHIFT + ALT + LEFT/RIGHT
-- binds, so one bind replaces the pair: following is now part of the move.
-- Moved off SUPER+CTRL+P, which is stock Power.
o.bind("SUPER + ALT + P", "Move workspace to next monitor", o.workspaces.move_to_monitor("+1"))

-- Window management. Both stay on Q so the reflex survives; only the modifiers
-- changed. SUPER+Q (Close window) and SUPER+CTRL+Q (Calculator) keep their
-- stock behaviour.
--
-- Omarchy also ships the calculator on SUPER+SHIFT+Q (default/hypr/bindings/
-- applications.lua). That chord belongs to the window actions here, so the
-- stock one is dropped first; the dedicated XF86Calculator key still opens
-- omacalc. Unbind before binding, or the reload removes the bind added below.
hl.unbind("SUPER + SHIFT + Q")
o.bind("SUPER + SHIFT + Q", "Force kill active window", scripts .. "/force-kill-active.sh")
o.bind("SUPER + SHIFT + ALT + Q", "Restart active window", scripts .. "/restart-active.sh")

-- ---------------------------------------------------------------------------
-- Window rules

-- The pop terminal launched by yadm/scripts/launch-pop-terminal.sh. Placing it
-- with a rule rather than from the script means it maps already floating,
-- centred and pinned, instead of appearing tiled for a frame and being moved.
-- size takes a table, not a string: `size = "50% 50%"` parses without error and
-- is then silently ignored, leaving the window at its own default dimensions.
-- The entries may be Hyprland expressions, as in default/hypr/apps/webcam-overlay.lua.
o.window("org.omarchy.pop-terminal", {
  float = true,
  pin = true,
  center = true,
  size = { "(monitor_w/2)", "(monitor_h/2)" },
})

o.window("re.fossplant.songrec", { tag = "+floating-window", float = true })
o.window("re.fossplant.songrec", { size = { "(monitor_w/2)", "(monitor_h/2)" } })

-- The games dock (a foot window with app-id game-dock, opened by XF86Mail):
-- float and centre it instead of tiling it into the current workspace.
o.window("game-dock", { float = true, center = true })

-- PES 2013 (Wine) -- keep it in a real fullscreen surface.
--
-- The game's D3D9 window is a plain 1920x1080 borderless window, not a
-- compositor fullscreen surface, so Hyprland tiled it: the 4px border and
-- gaps showed up as a frame around the pitch, and any focus change (pressing
-- SUPER, switching workspaces) re-tiled it and made that frame pop back in
-- mid-match. Forcing fullscreen from a window rule pins it to the whole
-- monitor with no border, whatever the game does to its own window.
--
-- Matched on title as well as class: Wine reports the class as the exe name
-- (pes2013.exe) and the window is titled "Pro Evolution Soccer 2013" (checked
-- with hyprctl clients while the game was running). Two rules so either match
-- is enough.
o.window({ title = "(?i)(PES ?2013|Pro Evolution Soccer 2013)" }, {
  border_size = 0,
  idle_inhibit = "fullscreen",
})
o.window("(?i)^(pes2013|konami).*", {
  border_size = 0,
  idle_inhibit = "fullscreen",
})

-- PES 2013 also treats a bare Windows/Super keypress as "leave fullscreen".
-- Omarchy leaves SUPER unbound on its own, so Hyprland hands the keypress to
-- the focused client and the game drops to a 1924x1084 Wine-decorated window
-- (title bar plus border) mid-match. Binding SUPER alone to a no-op swallows
-- that keypress; SUPER + <key> chords are matched separately and still work.
o.bind("SUPER + Super_L", "Swallow bare SUPER (PES 2013 leaves fullscreen)", function() end)
o.bind("SUPER + Super_R", "Swallow bare SUPER (PES 2013 leaves fullscreen)", function() end)


-- ---------------------------------------------------------------------------
-- Codeforces workspace

-- Solving a problem wants three things at once: the statement on the left, the
-- editor above a shell that runs it on the right. The right column is narrower
-- than the left one, and the editor taller than the shell.
--
-- Hyprland 0.57 can register a layout in Lua and a workspace can select it as
-- "lua:<name>". Doing this as a layout rather than as a one-off resize script
-- means the panes keep their places when a window is closed and reopened, and
-- the order the apps finish starting in does not matter: targets are slotted
-- by class, not by opening order. yadm/scripts/cf-workspace.sh launches the
-- panes; this file decides where they go.
--
-- The ratios are the ones workspace 3 was set up with by hand: 1236px of the
-- 1892px content width for the browser, 534px of the 1026px height for nvim.
local CF_LEFT_RATIO = 0.65
local CF_EDITOR_RATIO = 0.52

-- Browser left, nvim top right, everything else bottom right. "Everything
-- else" is normally the run terminal (foot, or the app-id that
-- cf-workspace.sh gives it); a man page or a second shell stacks there too.
local function cf_pane(target)
  local class = target.window and target.window.class or ""

  if class:match("^brave%-browser$") or class:match("chromium") or class:match("firefox") then
    return 1
  elseif class:match("org%.omarchy%.nvim") then
    return 2
  end

  return 3
end

-- Place a group of targets side by side in one box without leaving a gap.
-- ctx:split returns the box on the named side, so n targets become n columns.
local function cf_place_row(ctx, targets, box)
  local n = #targets

  if n == 0 then
    return
  elseif n == 1 then
    targets[1]:place(box)
    return
  end

  targets[1]:place(ctx:split(box, "left", 1 / n))
  cf_place_row(ctx, { table.unpack(targets, 2) }, ctx:split(box, "right", (n - 1) / n))
end

hl.layout.register("codeforces", {
  recalculate = function(ctx)
    local browser, editor, other = {}, {}, {}

    for _, target in ipairs(ctx.targets) do
      local pane = cf_pane(target)
      local group = pane == 1 and browser or pane == 2 and editor or other
      group[#group + 1] = target
    end

    -- Closing the browser gives its column back to the editor and terminal
    -- instead of leaving an empty strip; a lone pane fills the workspace.
    local right = ctx.area
    if #browser > 0 and (#editor > 0 or #other > 0) then
      cf_place_row(ctx, browser, ctx:split(ctx.area, "left", CF_LEFT_RATIO))
      right = ctx:split(ctx.area, "right", 1 - CF_LEFT_RATIO)
    else
      cf_place_row(ctx, browser, right)
    end

    if #editor > 0 and #other > 0 then
      cf_place_row(ctx, editor, ctx:split(right, "top", CF_EDITOR_RATIO))
      cf_place_row(ctx, other, ctx:split(right, "bottom", 1 - CF_EDITOR_RATIO))
    else
      cf_place_row(ctx, editor, right)
      cf_place_row(ctx, other, right)
    end
  end,
})

-- Workspace 3 on the daily monitor is the Codeforces one. A one-off layout
-- change (SUPER + L, or cf-workspace.sh --here on another workspace) overrides
-- this for the session; a reload brings the rule back.
hl.workspace_rule({ workspace = "3", layout = "lua:codeforces" })


-- ---------------------------------------------------------------------------
-- Added plugins

-- Lock Screen Explorer
o.bind("SUPER + ALT + L", "Lock screen explorer", "omarchy-shell lock explore")

