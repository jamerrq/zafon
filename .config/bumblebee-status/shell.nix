{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    python312Packages.psutil
    python312Packages.pydbus
    python312Packages.dbus-python
    python312Packages.netifaces
    xdg-utils
    xdotool
    libnotify
    killall
    dunst
    pulseaudio
    bluez
    
  ];
}
