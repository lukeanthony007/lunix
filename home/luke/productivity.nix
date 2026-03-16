{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deluge-gtk
    discord
    obsidian
    signal-desktop
    zoom-us
  ];
}
