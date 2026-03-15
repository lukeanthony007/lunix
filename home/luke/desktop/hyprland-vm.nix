{ lib, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    "$mod" = lib.mkForce "CTRL";
    # VM virtual display — auto-detect resolution
    monitor = lib.mkForce ",preferred,auto,1";
    # Direct foot launch with full path
    bind = lib.mkBefore [
      "CTRL, Return, exec, ${pkgs.foot}/bin/foot"
    ];
  };
}
