---
name: zafon
description: >
  Machine context for jamerrq's Omarchy/Hyprland laptop (host "nikki", yadm
  dotfiles repo "zafon", branch capablanca). Use before touching anything
  personal on this machine: ~/.config/hypr/zafon.lua and keybinds, monitors and
  window rules, yadm/zafon dotfile work and commits, zsh aliases and shell
  functions in ~/.config/zsh, PATH precedence, Omarchy packaged files, the games
  dock / Lutris / Wine setup, OpenCode agents and skills, or when asked what
  this machine's layout, preferences or helper commands are. Triggers: zafon,
  yadm, capablanca, dotfiles, zafon.lua, zafon.d, aliases, shell functions,
  wine-ge, game dock, games.conf, monitors HDMI-A-1/HDMI-A-2, grim, Lutris,
  PES 2013, GTA SA, OpenCode config, omarchy PATH, keybinding conflict.
---

# zafon — this machine's context

`zafon` is the name of both this laptop and its dotfiles repo. Everything
personal lives in one yadm work tree (`$HOME`), branch `capablanca`, remote
`git@github.com:jamerrq/zafon.git`. Read this before editing personal config;
load the `omarchy` skill too when the change is about Omarchy itself.

## Hard rules

- **Use `yadm`, never plain `git`.** `yadm status`, `yadm add`, `yadm commit`.
  `git` in `$HOME` cannot see these files.
- **`yadm status -uall` is useless** — `$HOME` holds ~1.2M untracked files.
  Use plain `yadm status`, or `zafon untracked` (scoped to directories that
  already hold tracked config).
- **Never edit `/usr/share/omarchy/` or `~/.local/share/omarchy`** (a symlink to
  it). It is the `omarchy-dev` package; upgrades overwrite it. Reading is fine.
  Patched scripts live in `~/.config/yadm/omarchy/bin/` and are symlinked into
  `~/.local/bin`.
- **Never edit `/usr/share/omarchy/shell/`** — bar, notifications, OSD,
  launcher, menu, lock screen are Quickshell plugins. To change one,
  `omarchy plugin clone <id>` (weigh the fork first).
- **Back up before editing** personal config or game data: timestamped
  `.bak.<epoch>` next to the file, or `~/Games/<game>/backup/`.
- **`set -o noclobber` is on** in the interactive shell: `>` will not overwrite
  an existing file. Use `>|` when you mean it.
- **Don't `pkill -f <pattern>`** — it can match the shell running it. Find the
  PID with `pgrep -x`/`ps` and `kill <pid>`.
- **This is a shared machine.** The user may be working while you are. Ask
  before taking over a monitor, focusing/raising a game, switching workspaces,
  pausing media, or needing a few minutes AFK.

## The machine

- Host `nikki`; Omarchy 4.x (quattro) on Arch, Wayland, Hyprland with a **Lua**
  config. Intel i7-1355U / Iris Xe. zsh is the login shell.
- Omarchy is a pacman package now; `omarchy update` is a package upgrade.
- Two 1080p panels, scale 1:
  - `HDMI-A-1` at `0x0`, 1920x1080 — terminal / daily workspace.
  - `HDMI-A-2` at `1920x0`, 1920x1080@75 — games, usually fullscreen.
  - Mode/scale/arrangement are owned by the **monitor panel** in the top bar;
    its state is saved in `~/.local/state/omarchy/monitors/settings`. Don't
    hardcode refresh rates in config unless deliberately overriding the panel.
- Screenshot: `grim -o HDMI-A-2 /tmp/opencode/x.png` (or `HDMI-A-1`).
- Inspect: `hyprctl monitors -j`, `hyprctl workspaces -j`, `hyprctl clients -j`.

## Repo layout (`~/.config/yadm/`)

```
bootstrap              # runs on `yadm bootstrap` after clone
zafon                  # the CLI, symlinked -> ~/.local/bin/zafon
zafon.art              # banner art, hand-edited (colors from cava config)
zafon.d/               # one module per customization: `check` + `apply`
zafon.d/lib/           # shared helpers, NOT modules (glob is *.sh)
omarchy/bin/           # patched Omarchy scripts -> symlinked into ~/.local/bin
system/                # root-owned files + install.sh (needs sudo)
scripts/               # helper scripts bound to keys in hypr/zafon.lua
editors/               # VS Code / Antigravity extension lists
wallpapers/            # copied into the active theme's backgrounds/
CLAUDE.md              # the long-form conventions doc; read it for repo work
```

Personal config tracked outside that directory: `.config/hypr/zafon.lua`,
`.config/zsh/`, `.config/omarchy/shell.{json,toml}`, `.config/opencode/`,
`.zshenv`, `.config/uwsm/env.d/99-zafon-path`.

## zafon CLI

`zafon [apply|check|list|tree|untracked|logo]` — modules are
`10-hypr`, `20-bar`, `30-omarchy-bin`, `40-zsh`, `50-theme`, `60-system`,
`70-wallpaper`.

- `zafon check` reports drift, changes nothing; `zafon apply` walks modules
  needing work and confirms each; `-y` skips prompts (optional modules still
  skipped); `-o a,b` limits modules; `-s` only problems.
- Module exit codes: `0` ok, `1` drift, `2` missing, `3` error.
- **Check state, not files.** Assert on what the running system reports
  (`hyprctl getoption`, `omarchy-shell media status`, `pactl`, a PTY-backed
  interactive shell) — a config can contain the right lines and still not take
  effect. And **verify the check fails** by breaking the thing on purpose.
- Probing an interactive zsh needs a PTY: use `zafon.d/lib/shell-probe.sh`
  (`zsh -i -c` without a TTY breaks p10k/gitstatus and prints noise).

## Hyprland

- Omarchy owns `hyprland.lua` and the stock topic files (`monitors.lua`,
  `input.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`). **All personal
  config is `~/.config/hypr/zafon.lua`**, required last from `hyprland.lua`
  (`require("hypr.zafon")`) so it wins over defaults and topic files. Keep topic
  files stock so `omarchy refresh config hypr/<topic>.lua` stays safe.
- Binds: `o.bind("SUPER + X", "Description", "command")` or
  `{ launch = "...", focus = "..." }`. **Don't unbind Omarchy defaults** — move
  the personal binding to a free chord so `omarchy menu keybindings --print`
  stays accurate (`omarchy-menu-keybindings -p | grep -i <thing>`).
- Window rules: prefer declarative `o.window("class", { float = true, center = true })`.
  `size` wants a **table**: `size = { "(monitor_w/2)", "(monitor_h/2)" }`;
  a string parses and is silently ignored.
- `hyprctl dispatch` takes **Lua** in this config. Bare keywords fail:
  `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'` is correct;
  `hyprctl dispatch closewindow "class:x"` is a syntax error.
- After any change: `hyprctl reload` then `hyprctl configerrors` (must be empty).
  A Lua error can leave the file intact while the compositor silently falls back
  to defaults, so also check live values with `hyprctl getoption <opt> -j`.

## PATH — two of them, and they differ

- **Session** PATH: `~/.config/uwsm/env.d/99-zafon-path` puts `~/.local/bin`
  first. uwsm sources `env.d/*` and pushes it into the systemd user manager
  *after* the `environment.d` generators, so `environment.d` cannot fix ordering.
- **Keybind dispatcher** PATH: Omarchy's `default/hypr/envs.lua` forces
  `$OMARCHY_PATH/bin` to position 1; `zafon.lua` re-asserts `~/.local/bin`
  first and wins because it loads last.
- The `omarchy` dispatcher execs `$OMARCHY_BIN_DIR/<binary>` by **absolute
  path** and ignores PATH. Anything that must hit a patched script calls it
  directly (`omarchy-brightness-display +5%`), never via `omarchy brightness ...`.
- Failure mode is silent: `/proc/<hyprland>/environ` can look right while a
  keybind still runs the packaged copy. `zafon.d/30-omarchy-bin.sh` checks both.

## Zsh

- `~/.zshenv` exists only to set `ZDOTDIR=$HOME/.config/zsh` (zsh reads it
  before it knows ZDOTDIR). Config and generated state (`history`, `zcompdump`)
  live under `$ZDOTDIR`.
- Aliases and functions: `~/.config/zsh/.zsh_aliases`. `$ZSH` is
  `~/.config/zsh/.oh-my-zsh` (omz, p10k, autosuggestions, syntax-highlighting
  are nested git repos, cloned by `zafon.d/40-zsh.sh`).
- **The tail of `.zsh_aliases` redefines every `g*`/`y*` alias as a function**
  that echoes the command first. Consequence: a launcher written as an alias
  becomes a blocking foreground command. **Write launchers as functions.**
- `y*` aliases map to `yadm`, generated into `.zsh_yadm_aliases`. Test with
  `$+functions[yss]`; `$+aliases[yss]` is always 0.
- Useful aliases: `zafon-hypr-config`, `zsh-aliases`, `nvim-config`,
  `hypr-config`, `t1/t2/t3`, `yt` (yadm tree), `ezala`, `py3`, `uvI`, `st`, `cm`.
- Wine: `wine-ge` → `wine-ge-8-26` →
  `~/.local/share/lutris/runners/wine/wine-ge-8-26-x86_64/bin/wine`.
- Games (functions, non-blocking): `gamedock`, `mc` (Minecraft/Prism),
  `pes` (id 5), `pesorig` (id 7), `gtasa` (id 3), `gtasaopti` (id 4).

## Games

- Lutris DB `~/.local/share/lutris/pga.db`; per-game YAML in
  `~/.local/share/lutris/games/`.
  - `3` GTA SA MODDED — `~/Games/GTA SA MODDED/gta_sa.exe`
  - `4` GTA SA (Opti V3.1) — `~/Games/GTA SA Opti V3.1/gamedata/gta_sa.exe`
  - `5` PES 2013 — `~/Games/PES2013/pesdata/pes2013.exe`
  - `7` PES 2013 (Original 1.4) — same prefix, `pes2013_original.exe`
- Launch:
  `cd <working_dir> && LUTRIS_SKIP_INIT=1 nohup ~/.local/bin/lutris lutris:rungameid/<id> >/tmp/lutris-<id>.log 2>&1 &`
  (takes ~30 s to reach a title screen).
- **Minecraft** runs through Prism Launcher (`/usr/bin/prismlauncher`), not
  Lutris. One instance: id `DRAFTOUT` (folder name in
  `~/.local/share/PrismLauncher/instances/`). Launch it directly with
  `prismlauncher --launch DRAFTOUT` (the launcher window closes itself,
  `CloseAfterLaunch=true`); shell helper `mc`. Prism keeps `SUPER + ALT + M`;
  the mail key belongs to the games dock.
- **Games dock**: `~/.local/bin/game-dock`, bound to `XF86Mail` in `zafon.lua`
  (Prism Launcher keeps `SUPER + ALT + M`). It is a floating `foot` window with
  app-id `game-dock`; the `o.window("game-dock", { float = true, center = true })`
  rule lives in `zafon.lua`. List: `~/.config/game-dock/games.conf`, one
  `Label|command` per line, line order = the number pressed. `q`/`Esc` closes.
  To close it from a script, kill the `foot --app-id=game-dock` PID (the Lua
  config rejects `closewindow "class:..."`).
- PES menu sounds are silenced by zeroing the `volume` column of every TBLSYN row
  in AFS entry 28 (CRI "SYSTEM" SE bank) of `~/Games/PES2013/pesdata/img/dt03.img`
  (offset 761856, size 708288). Backup:
  `~/Games/PES2013/backup/dt03_entry28_system.acb`; tool
  `~/Games/PES2013/backup/afs_replace.py`.
- `~/.local/bin/pes2013-refresh 60|restore` switches refresh rate and resumes
  MPRIS on exit; PES prefix is `~/Games/pes2013-prefix`.
- Audio: PipeWire, HDMI sink `alsa_output.pci-0000_00_1f.3.hdmi-stereo`; numeric
  sink ids change, read them from `pactl list short sinks` before
  `pw-record --target <id>`. Game audio appears as sink-input
  `application.name = "Pro Evolution Soccer 2013"`. **Ask before muting or
  pausing other media** (`playerctl`).
- Input automation: `xdotool` against XWayland — focus the window first, then
  `xdotool key --window $WID --clearmodifiers --delay 120 <key>`.

## OpenCode

- Config `~/.config/opencode/`: `opencode.json` (schema, `autoupdate: false`),
  `cli.json` (theme, keybinds, plugins), `agents/`, `skills/`.
- Global agents: `~/.config/opencode/agents/<name>.md`. `game-setup.md` is the
  games/Lutris/Hyprland helper (`mode: all`; asks before `sudo`, `systemctl`,
  `pkill`, `kill`, `playerctl`).
- Global skills: `~/.config/opencode/skills/<id>/SKILL.md`. Omarchy ships its
  skills at `/usr/share/omarchy/default/agents/skills/` and exposes them through
  `~/.claude/skills` symlinks; `~/.config/opencode/skills` is a global source
  too (higher precedence), so anything there is available to every agent.
- State DB `~/.local/share/opencode/opencode.db` (sessions, messages, tools).
  Usage: `opencode stats --all --cost`, or the console at
  `https://opencode.ai/console/org_01M4FJK74W25HY0N9FZ413J7GB/usage`.
- Free-tier models work only **inside** OpenCode; direct API `curl` returns
  `429 FreeUsageLimitError` by design. Paid models need credits ($0 balance).
- Add an agent/skill as Markdown with YAML frontmatter; validate by running
  `opencode run --archived --agent <name> "reply OK"`.

## Conventions and preferences

- **Commit messages:** lowercase topic prefix, then *why* rather than *what*
  (`zsh: ...`, `omarchy: ...`, `hypr: ...`, `chore: ...`). Stage only related
  files; `$HOME` usually has unrelated drift in tracked files.
- **Comments explain why**, especially non-obvious behaviour, upstream quirks,
  PATH precedence, toggling semantics.
- Bash modules: `#!/bin/bash`, 2-space indent, `set -uo pipefail` (not `-e`,
  which would abort a check on its first negative result).
- Scripts/scratch go in `/tmp/opencode` and get cleaned up.
- Prefer read-only inspection first; announce intrusive actions and keep them
  reversible. When done, report what changed, the backup path, how to undo it,
  and what you actually verified (screenshot, log line, live `hyprctl` value).

## Fast diagnostics

```bash
hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate|floor) ws=\(.activeWorkspace.name)"'
hyprctl clients -j | jq -r '.[] | "\(.class) | \(.title) | ws \(.workspace.name)"'
hyprctl configerrors
hyprctl getoption decoration:rounding -j
yadm status
zafon check
pactl list short sinks
```
