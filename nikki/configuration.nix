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
      # daily
      brave                # browser
      spotify              # music

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
      qemu                 # virtualization
    ];
    shell = pkgs.zsh;
  };

  # system packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # utilities
    cava                   # audio visualization
    eza                    # ls replacement
    fastfetch              # system information
    feh                    # image viewer
    fzf                    # fuzzy finder
    imagemagick            # image manipulation
    keyd                   # keyboard mapper
    libnotify              # notification system
    libsForQt5.kruler      # ruler
    libwebp                # webp image manipulation
    lxde.lxsession         # classic lxde session manager
    neovim                 # text editor
    networkmanagerapplet   # network manager applet
    pavucontrol            # audio control
    playerctl              # media player controller
    ranger                 # file manager
    ripgrep                # search tool
    timg                   # image & video viewer
    unzip                  # unzip files
    zoxide                 # cd replacement

    # for sway (wayland)
    grim                   # screenshot functionality
    mako                   # notification system
    rofi-wayland           # rofi for wayland
    sherlock-launcher      # application launcher
    slurp                  # screenshot functionality
    swaybg                 # background for sway
    swayidle               # idle management
    swaylock-effects       # swaylock with effects
    swaynotificationcenter # notification center for sway
    waybar                 # bar for sway
    wdisplays              # display management (GUI)
    wl-clipboard           # copy/paste from stdin / stdout (wl-copy, wl-paste)
    wlogout                # logout menu for sway
    wlsunset               # screen color temperature
  ];

  # vm config
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  users.groups.libvirtd.members = ["jamerrq"];

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
