# Zafon - Capablanca

[![en](https://img.shields.io/badge/lang-en-red.svg)](./README.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](./README.es.md)

## My [Omarchy](https://omarchy.org/) customizations

- Rounded borders for walker, mako, and hyprland (10px)
- Thicker borders for hyprland and mako (size 4)
- Persistent custom wallpapers mapped natively into theme's backgrounds folder
- Use Arch Linux logo (`󰣇`) on the waybar and fastfetch
- System-wide enforcement of `FiraCode Nerd Font`
- Neovim `ColorColumn` visibility fix (`#1e6091`) + `unnamedplus` clipboard sync
- Keyboard layout input set to `latam`
- Custom monitor workspace navigation mimicking i3 behavior

## Quick Setup (New Machine)

To quickly deploy these dotfiles and apply all Omarchy customizations on a new machine, run:

```bash
yadm clone https://github.com/jamerrq/zafon -b capablanca
yadm bootstrap
```

`yadm bootstrap` runs [zafon](#zafon) non-interactively, which applies every
customization except the ones marked optional (those need sudo). Afterwards:

```bash
zafon check     # verify everything landed
zafon apply     # pick up the optional steps
```

Log out and back in once, so `~/.local/bin` takes effect for everything
Hyprland launches.

## Zafon

`zafon` is the CLI that applies and verifies these customizations. Each concern
is a module in `~/.config/yadm/zafon.d/`; `check` is strictly read-only, so it
is safe to run any time — including before an `omarchy-update`.

```
zafon                       # default: walk each problem and confirm before fixing
zafon check                 # report drift, change nothing
zafon apply --yes           # unattended; skips optional (sudo) modules
zafon check --only waybar   # scope to one module
zafon list                  # show all modules
zafon tree                  # every tracked file as a tree
```

Exit codes: `0` all good, `1` drift remains or a module failed, `3` usage error.

| Module | Covers |
| --- | --- |
| `hypr` | `nikki.conf` sourced from `hyprland.conf`, keybound helper scripts |
| `waybar` | config, style and custom scripts — yadm is the source of truth |
| `omarchy-bin` | patched Omarchy scripts shadowing the clone via `~/.local/bin` |
| `zsh` | omz, powerlevel10k and custom plugins (cloned, not tracked) |
| `theme` | rounded mako/walker templates, FiraCode, custom wallpapers |
| `system` | root-owned units (ACPI wakeup fix) — optional, needs sudo |
| `wallpaper` | offers the tux wallpaper as a last step — optional, declining keeps yours |

### How the Omarchy overrides work

`~/.local/share/omarchy` is a git checkout of upstream Omarchy, so editing
scripts in place means `omarchy-update` clobbers them. Patched copies live in
`~/.config/yadm/omarchy/bin/` and are symlinked into `~/.local/bin`, which
`~/.config/environment.d/10-zafon-path.conf` puts ahead of Omarchy's `bin` on
the systemd user PATH. The clone stays pristine.

One caveat: the `omarchy` dispatcher execs `$OMARCHY_BIN_DIR/<binary>` by
absolute path and ignores PATH. Call patched scripts directly
(`omarchy-brightness-display +5%`), not via `omarchy brightness display +5%`.

### Waybar

Do not run `omarchy-refresh-waybar`. It copies Omarchy's defaults over
`~/.config/waybar/`, destroying the spotify and nightlight modules, the Arch
logo and the FiraCode font. The config is tracked in yadm instead;
`zafon apply --only waybar` restores it from the repo.

### ACPI wakeup

Some devices (`XHCI`, `RP09`, `RP10`, `RP05`, `AWAC`) spuriously wake this
machine from suspend. `/proc/acpi/wakeup` is runtime state that resets to the
firmware defaults on every boot, so the fix has to be re-applied each time; a
oneshot systemd unit does that at startup.

```bash
~/.config/yadm/system/install.sh    # needs sudo, also run by `zafon apply`
systemctl status disable-acpi-wakeup
```

Writing a device name to `/proc/acpi/wakeup` *toggles* it, so the script guards
on `*enabled` before each write — without that guard, re-running it would
re-arm everything it just disabled.

## Requirements

Beyond a working Omarchy install:

```bash
yay -S yadm gum jq playerctl brightnessctl ddcutil scrcpy
```

- `yadm` — dotfile tracking
- `gum` — zafon's interactive menu (falls back to plain prompts if absent)
- `jq`, `playerctl` — waybar spotify module and audio switching
- `brightnessctl`, `ddcutil` — brightness, including external monitors over DDC/CI
- `scrcpy` — Android screen mirroring

## Snaps

![desktop10](./.config/lib/imgs/desktop_10.webp)

![desktop6](./.config/lib/imgs/desktop_6.webp)

![desktop7](./.config/lib/imgs/desktop_7.webp)

![desktop8](./.config/lib/imgs/desktop_8.webp)

![desktop9](.config/lib/imgs/desktop_9.webp)

![desktop11](./.config/lib/imgs/desktop_11.webp)

![desktop12](./.config/lib/imgs/desktop_12.webp)

![desktop13](./.config/lib/imgs/desktop_13.webp)

![desktop14](./.config/lib/imgs/desktop_14.webp)

![desktop15](./.config/lib/imgs/desktop_15.webp)

![desktop16](./.config/lib/imgs/desktop_16.webp)

![desktop17](./.config/lib/imgs/desktop_17.webp)

![desktop18](./.config/lib/imgs/desktop_18.webp)

![desktop19](./.config/lib/imgs/desktop_19.webp)

![desktop20](./.config/lib/imgs/desktop_20.webp)

More info:

- [omarchy.org](https://omarchy.org/)
- [Source code on GitHub](https://github.com/basecamp/omarchy)

## Missing

- [x] M1. zsh + omz setup — `.zshrc` tracked, omz/p10k/plugins cloned by zafon
- [x] M2. include some packages (scrcpy, yadm) — see [Requirements](#requirements)
- [ ] M3. spanish readme
- [ ] M4. grok and antigravity on walker (contrib)
- [x] M5. antigravity + vscode settings — settings + extension lists tracked
- [x] M6. update waybar config to date (aug 2026)
- [x] M7. expand readme (include yadm)
- [x] M8. fix broken waybar step — `omarchy-refresh-waybar` no longer runs
- [ ] M9. update yadm
- [x] M10. update to quattro

## Some ideas

- [ ] a way to pause the media sources in the bar widget
- [ ] let's wrap some of the desktop images and updated some of them (maybe to add categories)
- [ ] let's discuss about the behaviour of the pause/resume button when there are more than one source