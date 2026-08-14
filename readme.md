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
chmod +x ~/.config/yadm/bootstrap
yadm bootstrap
```

This will check if the setup is correct and apply the customizations.

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

- M1. zsh + omz setup
- M2. include some packages (scrcpy, yadm)
- M3. spanish readme
- M4. grok and antigravity on walker (contrib)
- M5. antigravity + vscode settings
- M6. update waybar config to date (aug 2026)
- M7. expand readme (include yadm)
- M8. fix broken waybar step
- M9. update yadm

## Ideas for the script (zafon)

- I1. ascii art
- I2. some optional steps
- I3. flags (--silent, --verbose, etc.)
- I4. interactive menu like gum
- I5. preferible to use bash, if not possible, then python
- I6. let's use progress bars along
