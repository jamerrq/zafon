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
hl.config({
  general = {
    border_size = 4,
  },
  decoration = {
    rounding = 10,
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

-- ---------------------------------------------------------------------------
-- Monitors
--
-- Scale is deliberately 1 on both: these are 1080p panels, nothing to scale up.
-- The matching omarchy_monitor_scale / omarchy_gdk_scale knobs are in
-- hypr/monitors.lua. HDMI-A-1 ran at 75Hz before quattro; the LG reports 100Hz
-- as a supported mode, so both are pinned to 100.

hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@100", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@100", position = "1920x0", scale = 1 })

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

-- Suspend. Not on SUPER+SHIFT+S (Google Maps) and not on SUPER+CTRL+S (Share);
-- both are stock bindings and both are left alone.
o.bind("SUPER + CTRL + SHIFT + S", "Suspend", "systemctl suspend")

-- Media / extra keys.
o.bind("XF86HomePage", "Pop terminal", scripts .. "/launch-pop-terminal.sh")
o.bind("XF86Mail", "Email", "omarchy-launch-browser")
o.bind("SUPER + XF86Calculator", "Toggle bluetooth", scripts .. "/toggle-bluetooth.sh")

-- Audio output switching has no binding here. Omarchy's own SHIFT + Mute is
-- left in place, and once the session picks up uwsm/env.d/99-zafon-path it
-- resolves omarchy-audio-output-switch to the ~/.local/bin override by PATH
-- precedence. Until that relaunch it runs the packaged copy, which cannot
-- switch a single-sink card.

-- Apps.
o.bind("SUPER + SHIFT + L", "Lichess", { webapp = "https://lichess.org" })
o.bind("SUPER + SHIFT + Z", "Antigravity", "antigravity --disable-gpu")

-- Brightness has no binding on purpose: the bar's omarchy.monitor widget
-- covers it, and it drives the display over DDC without a keybind.

-- Monitors.
o.bind("SUPER + U", "Focus next monitor", hl.dsp.focus({ monitor = "+1" }))
-- hl.dsp.window.move has no monitor option (it accepts only direction,
-- x+y, workspace, into_group, out_of_group), so this one goes through
-- hyprctl to reach Hyprland's `movewindow mon:` form.
o.bind("SUPER + SHIFT + U", "Move window to next monitor", "hyprctl dispatch movewindow mon:+1")

-- Pushing a workspace to the other monitor follows it there, mimicking i3.
-- Two binds on one key fire in order (same trick tiling.lua uses for ALT+TAB).
-- Moved off SUPER+CTRL+P, which is stock Power.
o.bind("SUPER + ALT + P", "Move workspace to next monitor", hl.dsp.workspace.move({ monitor = "+1" }))
o.bind("SUPER + ALT + P", "Move workspace to next monitor", hl.dsp.focus({ monitor = "+1" }))

-- Window management. Both stay on Q so the reflex survives; only the modifiers
-- changed. SUPER+Q (Close window) and SUPER+CTRL+Q (Calculator) keep their
-- stock behaviour.
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
