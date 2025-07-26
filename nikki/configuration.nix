{ config, pkgs, lib, ... }:

{
  imports =
    [ ./hardware-configuration.nix ];

  # bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # network
  networking.hostName = "nikki";
  networking.networkmanager.enable = true;

  # timezone
  time.timeZone = "America/Bogota";

  # locale
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

  # keyboard
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };
  console.keyMap = "la-latin1";

  # shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # users config
  users.users.jamerrq = {
    isNormalUser = true;
    description = "Jamer José";
    extraGroups = [ "networkmanager" "wheel" "vboxusers" "libvirtd" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # system packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    i3
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
    docker
    dbeaver-bin
    picom
    zoxide
    feh
    betterlockscreen
    libnotify
    # virtualbox
  ];

  # vm config
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.virtualbox.host.enable = true;

  # xorg config
  services.xserver.enable = true;
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  programs.dconf.enable = true;

  # fonts
  fonts.fontconfig.enable = true;
  fonts.packages = [
    pkgs.nerd-fonts.shure-tech-mono
    pkgs.nerd-fonts.fira-code
  ];

  # docker config
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # nix config
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };
  system.stateVersion = "25.05";
}
