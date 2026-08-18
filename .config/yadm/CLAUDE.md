# zafon — dotfiles for Omarchy (capablanca)

Personal dotfiles tracked with [yadm](https://yadm.io/). The work tree is
`$HOME`; the remote is `git@github.com:jamerrq/zafon.git`, branch `capablanca`.

## Working in this repo

- **Use `yadm`, not `git`.** `yadm status`, `yadm add`, `yadm commit`. Plain
  `git` in `$HOME` will not see these files.
- **`yadm status -uall` is useless here** — `$HOME` has ~1.2M untracked files.
  Use `yadm status` (default, `-unormal`) or scope the path.
- Shell aliases: `gss` etc. come from the omz `git` plugin; the `y*` equivalents
  (`yss`, `yaa`, …) are generated into `.config/zsh/.zsh_yadm_aliases` from that
  plugin's source and map to `yadm`.

## Layout

```
.config/yadm/
├── bootstrap              # runs on `yadm bootstrap` after clone
├── check.sh               # legacy linear check; being superseded by zafon
├── zafon                  # the CLI (symlinked -> ~/.local/bin/zafon)
├── zafon.art              # banner art -- hand-edited, do not regenerate
│                          #   (gradient colors come from ~/.config/cava/config)
├── zafon.d/               # one module per customization, each a `check`/`apply` script
├── omarchy/bin/           # patched Omarchy scripts (symlinked -> ~/.local/bin/)
├── system/                # root-owned files + install.sh (needs sudo)
├── editors/               # VS Code / Antigravity extension lists
├── scripts/               # helper scripts bound to keys in nikki.conf
└── wallpapers/            # copied into the active theme's backgrounds/
```

## Two things that are easy to get wrong

**1. Never edit scripts inside `~/.local/share/omarchy/`.** That directory is a
git checkout of `basecamp/omarchy`; `omarchy-update` pulls there and will
clobber local edits. Patched copies live in `.config/yadm/omarchy/bin/` and are
symlinked into `~/.local/bin`, which `.config/environment.d/10-zafon-path.conf`
places ahead of Omarchy's `bin` on the systemd user PATH.

Caveat: the `omarchy` dispatcher execs `$OMARCHY_BIN_DIR/<binary>` by absolute
path, so it **ignores PATH**. Anything that must hit a patched script has to
call it directly (`omarchy-brightness-display +5%`), not through the dispatcher
(`omarchy brightness display +5%`). See the binds in `.config/hypr/nikki.conf`.

**2. Never call `omarchy-refresh-waybar`.** It copies
`~/.local/share/omarchy/config/waybar/*` over `~/.config/waybar/*`, destroying
the spotify/nightlight modules, the Arch logo and the FiraCode font. The waybar
config is tracked in yadm and is the source of truth. `omarchy-refresh-hyprland`
*is* still called — user customizations live in the separate `nikki.conf`, which
`check.sh` re-sources afterwards.

## Hyprland config

Omarchy owns `hyprland.conf`, `bindings.conf`, `looknfeel.conf` etc. and
overwrites them on refresh. All customization goes in `.config/hypr/nikki.conf`,
sourced from the bottom of `hyprland.conf`.

## Oh My Zsh

`$ZSH` is `~/.config/zsh/.oh-my-zsh`, **not** the default `~/.oh-my-zsh`. Omz,
powerlevel10k, zsh-autosuggestions and zsh-syntax-highlighting are all nested
git repos, so yadm cannot track their contents — `zafon.d/40-zsh.sh` clones them
when missing. Only `.zshrc` and `.config/zsh/*` are tracked.

## Conventions

- Bash, `#!/bin/bash`, 2-space indent, `set -euo pipefail` in new scripts.
- Comments explain *why*, especially where behaviour is non-obvious (toggling
  semantics, PATH precedence, clobbering).
- Commit messages: conventional-commit prefix, then why rather than what.
