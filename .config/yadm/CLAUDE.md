# zafon — dotfiles for Omarchy (capablanca)

Personal dotfiles tracked with [yadm](https://yadm.io/). The work tree is
`$HOME`; the remote is `git@github.com:jamerrq/zafon.git`, branch `capablanca`.

Targets **Omarchy 4.x (quattro)**. Quattro was a breaking release and most of
what follows is a consequence of it: Hyprland moved to Lua, waybar/mako/walker/
swayosd were replaced by Quickshell surfaces, and Omarchy itself became a pacman
package instead of a git checkout.

## Working in this repo

- **Use `yadm`, not `git`.** `yadm status`, `yadm add`, `yadm commit`. Plain
  `git` in `$HOME` will not see these files.
- **`yadm status -uall` is useless here** — `$HOME` has ~1.2M untracked files.
  Use `yadm status` (default, `-unormal`), or `zafon untracked`, which scopes the
  scan to directories that already hold tracked config.
- `gss` and friends come from the omz `git` plugin; the `y*` equivalents (`yss`,
  `yaa`, …) are generated into `.config/zsh/.zsh_yadm_aliases` and map to `yadm`.
  They are **functions, not aliases** — the tail of `.zsh_aliases` unaliases
  every `g*`/`y*` alias and redefines it as a function that echoes the command
  first. Test with `$+functions[yss]`; `$+aliases[yss]` is always 0.

## Layout

```
.config/yadm/
├── bootstrap              # runs on `yadm bootstrap` after clone
├── check.sh               # legacy linear check, fully superseded by zafon — delete
├── zafon                  # the CLI (symlinked -> ~/.local/bin/zafon)
├── zafon.art              # banner art -- hand-edited, do not regenerate
│                          #   (gradient colors come from ~/.config/cava/config)
├── zafon.d/               # one module per customization: `check` + `apply`
│   └── lib/               # shared helpers, NOT modules (the glob is *.sh, not recursive)
├── omarchy/bin/           # patched Omarchy scripts (symlinked -> ~/.local/bin/)
├── system/                # root-owned files + install.sh (needs sudo)
├── editors/               # VS Code / Antigravity extension lists
├── scripts/               # helper scripts bound to keys in hypr/zafon.lua
└── wallpapers/            # copied into the active theme's backgrounds/
```

Personal config outside this directory: `.config/hypr/zafon.lua`,
`.config/omarchy/shell.{json,toml}`, `.config/omarchy/bar/modules/arch.qml`,
`.config/omarchy/plugins/jamerrq.osd/`, `.config/uwsm/env.d/99-zafon-path`,
`.zshenv` and `.config/zsh/`.

## Four things that are easy to get wrong

**1. Omarchy is a package now.** `/usr/share/omarchy` is owned by
`omarchy-dev`; there is no `.git` in it and `omarchy update` is a package
upgrade. `~/.local/share/omarchy` is a compatibility symlink to it. Never edit
anything under either path — a package upgrade overwrites it. Patched copies
live in `.config/yadm/omarchy/bin/` and are symlinked into `~/.local/bin`.

Before patching an Omarchy script, **diff it against the packaged one first**.
Quattro absorbed several patches upstream, and a stale override is worse than
none: the brightness override had grown into a copy that broke the bar's own
brightness widget, because upstream had started passing flags it did not parse.

**2. There are two PATHs, and the keybind one is not the session one.**

- The *session* PATH comes from `~/.config/uwsm/env.d/99-zafon-path`, which puts
  `~/.local/bin` ahead of `/usr/bin`. uwsm sources `env.d/*` and pushes the
  result into the systemd user manager **after** the `environment.d` generators
  run, overwriting theirs — so `environment.d` cannot fix ordering here.
- The *keybind dispatcher* PATH is separate. Omarchy's
  `default/hypr/envs.lua` ends by forcing `$OMARCHY_PATH/bin` to position 1 and
  pushing it through `hl.env("PATH", …)`. Nothing in `uwsm/env.d` can beat that.
  `hypr/zafon.lua` re-asserts `~/.local/bin` at the front, and because it is
  required last, it wins.

The failure mode is silent and confusing: `/proc/<hyprland>/environ` shows the
right order while a keybind still runs the packaged copy. `zafon.d/30-omarchy-bin.sh`
checks both.

Separate caveat: the `omarchy` dispatcher execs `$OMARCHY_BIN_DIR/<binary>` by
absolute path and **ignores PATH entirely**. Anything that must hit a patched
script calls it directly (`omarchy-brightness-display +5%`), never through the
dispatcher (`omarchy brightness display +5%`).

**3. Never edit `/usr/share/omarchy/shell/`.** The bar, notifications, OSD,
launcher, menu and lock screen are Quickshell plugins living there. To change
one, `omarchy plugin clone <id>` copies it to `.config/omarchy/plugins/<user>.<id>`
and switches to the clone. Weigh the fork first: `jamerrq.osd` is 10KB and worth
owning, while `omarchy.menu` is a 54KB `Menu.qml` that would freeze at the
cloned version — the Arch logo is a 45-line custom bar module instead, so the
menu keeps getting upstream updates.

**4. Hyprland's `hyprctl dispatch` takes Lua now.** The old bracket-rule form
is a syntax error:

```
hyprctl dispatch exec "[float; size 900 600] foo"   # error: ']' expected near ';'
hyprctl dispatch "hl.dsp.exec_cmd('foo')"           # correct
```

Prefer a declarative `o.window(...)` rule over dispatching placement from a
script. Note `size` wants a **table**, not a string: `size = "50% 50%"` parses
without error and is then silently ignored, leaving the window at its default
dimensions. Use `size = { "(monitor_w/2)", "(monitor_h/2)" }`.

## Hyprland config

Omarchy owns `hyprland.lua` and the per-topic files (`monitors.lua`,
`input.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`). All personal
config lives in **`.config/hypr/zafon.lua`**, required last from `hyprland.lua`
so it overrides both Omarchy's defaults and the topic files. Those files stay
stock on purpose: `omarchy refresh config hypr/<topic>.lua` can then reset any of
them without touching a single personal setting.

Bindings: **do not unbind Omarchy defaults.** Where a chord is taken, move the
personal binding to a free one so `omarchy menu keybindings --print` stays an
accurate picture of the system. Find a free chord by grepping that list — the
short form still works: `omarchy-menu-keybindings -p | grep -i suspend`.

## Shell surfaces and theming

Border **radius** comes from Hyprland: the shell mirrors `decoration:rounding`
into `Style.cornerRadius`, so one value in `zafon.lua` rounds notifications, the
launcher, menus and every bar flyout. Only border **widths** are declared, in
`.config/omarchy/shell.toml` — and because user keys there beat the theme's own
`shell.toml`, they survive a theme switch, which the old mako/walker `.tpl`
files did not.

Theme state moved to `~/.local/state/omarchy/current/` (`theme.name`,
`background`). Nothing in `zafon.d/` hardcodes a theme name; the modules read
the current one, so switching themes surfaces as ordinary drift.

## Zsh

`~/.zshenv` is the only zsh file in `$HOME`, and exists solely to set
`ZDOTDIR=$HOME/.config/zsh` — zsh reads it before it knows about `ZDOTDIR`, which
is what makes it the one file that cannot move. Config *and* generated state
(`.zsh_history`, `.zcompdump-*`) live under `$ZDOTDIR`; the generated files are
gitignored.

`$ZSH` is `~/.config/zsh/.oh-my-zsh`. Omz, powerlevel10k, zsh-autosuggestions and
zsh-syntax-highlighting are nested git repos, so yadm cannot track their
contents — `zafon.d/40-zsh.sh` clones them when missing.

## Writing a zafon module

Each module is a standalone executable exposing `check` and `apply`, with
`# zafon:name=` / `# zafon:desc=` headers. Exit codes: `0` ok, `1` drift, `2`
missing, `3` error. Mark a module `# zafon:optional=true` when it encodes taste
rather than correctness — `--yes` runs skip those.

**Check state, not files.** This is the rule the whole tool turns on. A config
can contain exactly the right lines and still not take effect: sourced in the
wrong order, guarded by a false condition, or overridden later. Assert on what
the running system reports — `hyprctl getoption`, `omarchy-shell media status`,
`pactl`, or an actual interactive shell via `zafon.d/lib/shell-probe.sh`.

Every module that only compared paths was reporting a false green after quattro
moved them. That is the failure this convention exists to prevent.

**Verify the check fails.** After writing a check, break the thing on purpose and
confirm it reports. Two checks written here passed against a deliberately broken
config before being fixed — one compared `$+functions[p10k]`, which is set by the
theme whether or not the prompt config loaded.

**Probing an interactive shell needs a PTY.** `zsh -i -c` with no terminal cannot
enable zle or job control, so p10k's gitstatus fails and prints errors that say
nothing about the config. `lib/shell-probe.sh` wraps `script(1)` for this.

## Conventions

- Bash, `#!/bin/bash`, 2-space indent, `set -uo pipefail` in modules
  (`-e` would abort a check on its first negative result).
- Comments explain *why*, especially where behaviour is non-obvious: toggling
  semantics, PATH precedence, clobbering, upstream quirks worked around.
- Commit messages: conventional-commit prefix, then why rather than what.
- `set -o noclobber` is on in the interactive shell: `>` will not overwrite an
  existing file. Use `>|` when you mean it.

## Tasks

Ordered. Tiers 1–2 are cheap and reduce risk; 3 is scoped; 4–5 are feature work
best done once the ground below them stops moving.

### 1. Track what is generated but untracked

Both are the same shape — add files, then a `zafon.d` check that notices when
they drift — so do them together. Untracked means one careless command loses them.

- [ ] **Track `.config/omarchy/branding/`.** `screensaver.txt` was regenerated
      with `omarchy ascii "ZAFON" > ~/.config/omarchy/branding/screensaver.txt`
      and is already staged; `about.txt` is still untracked, and there is a
      stale `screensaver.txt.bak` to remove. Decide whether `about.txt` is worth
      owning or should stay Omarchy's. See omarchy's `manual/41-branding.md`.
- [ ] **Track the wallpapers.** `.config/yadm/wallpapers/` holds 7; let's
      update to use the ones on /home/jamerrq/.config/omarchy/backgrounds/miasma

### 2. Screenshot directory

- [ ] Set `OMARCHY_SCREENSHOT_DIR="$HOME/Pictures/screenshots"`. One line, and
      the decision is already made. `omarchy-capture-screenshot` reads it,
      falling back to `XDG_PICTURES_DIR` then `$HOME/Pictures`. It belongs in
      `~/.config/uwsm/env.d/` (not `uwsm/default`, which is the legacy path),
      and needs a Hyprland relaunch.

### 3. Plymouth boot logo

- [ ] `omarchy plymouth set '#1d2021' '#ebdbb2' logo.png` also restyles SDDM;
      `omarchy plymouth preview <bg> <fg> <logo.png> <out.png>` renders it
      first, and `omarchy plymouth reset` reverts.

      **Why the earlier attempt failed:** `~/Pictures/logos/tux.png` is
      **1920×1080** — a wallpaper, not a logo. A boot logo wants a small,
      roughly square, transparent PNG (a few hundred px). Source a proper one
      and re-run `preview` before `set`.

      Note the SDDM config was just repointed at `hyprland.lua`; if the greeter
      ever misbehaves, `/etc/sddm.conf.d/10-wayland.conf.pre-lua-merge.bak` is
      the revert.

### 4. Media widget behaviour

Both touch the same plugin, so settle the design in one pass.

**Start by enabling it:** `omarchy.media` is currently *disabled* and absent
from the bar layout, so there is no widget to fix yet — `omarchy plugin enable
omarchy.media` and place it before designing anything. Note the plugin is both a
`service` and a `bar-widget`; the service is what answers `omarchy-shell media
status`, which `omarchy-audio-output-switch` already depends on, so leave that
half alone.

Only clone (`omarchy plugin clone omarchy.media`) if the stock widget genuinely
cannot do it — check the fork's size against the value first (see "easy to get
wrong" #3).

- [ ] Enable the media widget and place it in the bar layout.
- [ ] Decide what pause/resume should do when more than one source is playing.
      This is a design question before it is an implementation one.
- [ ] A way to pause media sources from the bar widget.

### 5. Polish

- [ ] **Improve `zafon --logo`:** take over the terminal (alternate screen),
      hold the art until `q`/`Esc`, restore cleanly on exit. Animation via
      durdraw later. Self-contained, no dependency on anything above.
- [ ] **Wallpaper categories** — wrap and refresh the desktop images. Do after
      task 1 settles where they live.
- [ ] **Spanish readme** (M3). Last: documentation is cheapest to write once
      everything above has stopped changing.
- [ ] **Delete `check.sh`.** 108 lines, superseded by zafon, referenced by
      nothing but this file.

### Dropped

- ~~M4. grok and antigravity on walker~~ — obsolete. Walker is not the launcher
  in quattro (the Quickshell menu is), and the package is still installed but
  unused. Adding web apps is a different mechanism now.
- ~~M9. update yadm~~ — done; the quattro port is committed and pushed.
