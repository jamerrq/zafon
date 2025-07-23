{ config, pkgs, lib, ... }:

{
  imports =
    [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Bogota";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };

  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  console.keyMap = "la-latin1";

  users.users.jamerrq = {
    isNormalUser = true;
    description = "Jamer José";
    extraGroups = [ "networkmanager" "wheel" "vboxusers" "libvirtd" ];
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    i3
    python313Packages.pydbus
    python313Packages.psutil
    python313Packages.netifaces
    python313Packages.pip
    dbus
    pulseaudio
    # caffeine
    rofi
    kitty
    flameshot
    feh
    playerctl
    xorg.xmodmap
    xorg.xrandr
    xclip
    networkmanagerapplet
    redshift
    pavucontrol
    git
    git-lfs
    yadm
    zsh
    python3
    dunst
    windsurf
    spotify
    fzf
    eza
    vscode
    brave
    vim
    virt-manager
    qemu
    # virtualbox
  ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  services.xserver.enable = true;
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  programs.dconf.enable = true;

  fonts.fontconfig.enable = true;
  fonts.packages = [
    pkgs.nerd-fonts.shure-tech-mono
    pkgs.nerd-fonts.fira-code
  ];

  system.stateVersion = "25.05";
}

