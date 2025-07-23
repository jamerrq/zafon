# Nix OS

## Instalación exprés

ISO minimal/GUI: baja la 24.05, bootea.

Particiona (igual que siempre) y monta /mnt.

nixos-generate-config --root /mnt

Edita /mnt/etc/nixos/configuration.nix (ver ejemplo abajo).

nixos-install → reboot.

Tip: usa la opción --flake si ya quieres empezar “con estilo moderno” (sección 7).

## Anatomía de configuration.nix

nix
Copy
Edit
# /etc/nixos/configuration.nix
{ config, pkgs, ... }:

{
  # hardware
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  networking.networkmanager.enable = true;

  # users
  users.users.jose = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "audio" ];
    shell        = pkgs.zsh;
  };

  # desktop (x11 + i3)
  services.xserver = {
    enable = true;
    xkb.layout = "latam";
    displayManager.startx.enable = true; # startx style
    windowManager.i3.enable = true;
  };

  # sound, bluetooth, etc.
  hardware.pulseaudio.enable = true;

  # packages available system‑wide
  environment.systemPackages = with pkgs; [
    kitty dunst picom feh git
  ];

  system.stateVersion = "24.05"; # ¡no toques esto luego!
}

## Clona tu mundo con Home‑Manager
En vez de tirar dotfiles a mano, ponlos bajo control de Nix:

nix
Copy
Edit
# flakes.nix snippet
homeManagerModules = [
  inputs.home-manager.nixosModules.home-manager
];

# home.nix
{ pkgs, ... }:
{
  programs.i3 = {
    enable = true;
    config = ./i3/config; # tu viejo dotfile
  };

  programs.dunst = {
    enable = true;
    settings = ./dunst/dunstrc;
  };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [ timg betterlockscreen ];
}
Home‑Manager puede lanzarse en el login vía home-manager switch o como módulo desde configuration.nix. Ejemplos vivos en Discourse	nixos.org
.

## ¿Flakes o canales?

Canales (default): nix-channel --update, nixos-rebuild switch.

Flakes (experimental pero popular): un único flake.nix define inputs y outputs reproducibles; piensa en un package.json + lockfile	nixos.org
.

Habilita flakes en /etc/nix/nix.conf:

ini
Copy
Edit
experimental-features = nix-command flakes

## Comandos del día	Flakes	Canales
Instalar pkg sólo hoy	nix run nixpkgs#htop	nix-shell -p htop
Shell dev fija	nix develop	nix-shell
Rebuild sistema	sudo nixos-rebuild switch --flake .#hostname	sudo nixos-rebuild switch
Actualizar todo	nix flake update && nixos-rebuild switch	sudo nix-channel --update && nixos-rebuild switch
Rollback	sudo nixos-rebuild --rollback	igual

## Mantener paquetes fuera de nixpkgs
Overlay simple: añade derivaciones externas o versiones parcheadas.

Pinned flake input: clona un repo con url = "github:foo/bar";.

## Replicar tu ecosistema i3
Migra tu ~/.config/i3, dunst, picom, kitty, scripts a un repo.

Usa home.packages para dependencias de los scripts (notify-send, betterlockscreen…).

Declara servicios como services.bumblebee-status.enable = true; si existe módulo, o empaqueta tu módulo como overlay.

Variables de entorno para tus scripts: home.sessionVariables.

## Debugging y rollbacks
Cada rebuild crea /nix/var/nix/profiles/system-<N>-link.

Grub muestra generaciones; flecha abajo si algo falla.

nix-store --gc para limpiar huérfanos (o activa nix.gc.automatic = true;).

## Desarrollo software
devShell + direnv → enter carpeta, obtienes Python	3.12, Node, etc.

Docker en NixOS: virtualisation.docker.enable = true;.

## Recursos que enganchan
Manual oficial y release notes	nixos.org.

Libro “NixOS & Flakes para principiantes”	nixos.org.

Discourse y Matrix #nixos:matrix.org (tu solución express).

## Próximos pasos sugeridos
Instala en VM y prueba rollbacks a placer.

Porta tu i3 + home-manager config.

Pasa tu proyecto de scripts bash a un módulo flake.

Activa nix.gc.automatic y nix.optimise para no llenar disco.
