{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/luke";
    };
  };

  fonts.packages = with pkgs; [
    inter
    material-symbols
  ];
}
