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
  networking.extraHosts = ''
    127.0.1.1    nikki
  '';

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
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker"];
    packages = with pkgs; [
      # dev
      code-cursor          # ai code editor
      dbeaver-bin          # database manager
      docker               # containerization
      git                  # version control
      git-lfs              # git large file storage
      kitty                # terminal
      python3              # python
      vscode               # code editor
      yadm                 # dotfiles manager

      # vm
      qemu                  # virtualization

      # daily
      brave                 # browser
      spotify               # music
    ];
    shell = pkgs.zsh;
  };

  # system packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # utilities
    cava                 # audio visualization
    libnotify            # notification system
    eza                  # ls replacement
    fastfetch            # system information
    feh                  # image viewer
    fzf                  # fuzzy finder
    libsForQt5.kruler    # ruler
    neovim               # text editor
    networkmanagerapplet # network manager applet
    pavucontrol          # audio control
    playerctl            # media player controller
    ranger               # file manager
    timg                 # image & video viewer
    xorg.xmodmap         # keyboard remapping
    zoxide               # cd replacement

    # for sway (wayland)
    gammastep             # screen color temperature
    grim                  # screenshot functionality
    mako                  # notification system
    rofi-wayland          # rofi for wayland
    sherlock-launcher     # application launcher
    slurp                 # screenshot functionality
    swaybg                # background for sway
    swayidle              # idle management
    swaylock-effects      # effects for swaylock
    waybar                # bar for sway
    wdisplays             # display management (GUI)
    wl-clipboard          # copy/paste from stdin / stdout (wl-copy, wl-paste)

    # for i3 (xorg)
    # bumblebee-status
    # flameshot
    # i3-gaps
    # picom
    # redshift
    # rofi
    # xclip
    # xorg.xrandr
  ];

  # vm config
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  users.groups.libvirtd.members = ["jamerrq"];

  # xorg config
  # services.xserver = {
  #   enable = false;
  #   displayManager.lightdm.enable = true;
  #   windowManager.i3.enable = true;
  # };

  # dconf config
  # programs.dconf.enable = true;

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

  # bluetooth config
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # sway config
  services.gnome.gnome-keyring.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  programs.waybar = {
    enable = true;
  };
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };


  # nix additional config
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };
  system.stateVersion = "25.05";
}

