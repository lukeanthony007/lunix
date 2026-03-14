{
  config,
  lib,
  pkgs,
  ...
}:
{
  niri-flake.cache.enable = false;

  programs.dconf.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.gnome.gnome-keyring.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --cmd ${lib.escapeShellArg (lib.getExe' config.programs.niri.package "niri-session")}";
      user = "greeter";
    };
  };

  environment.systemPackages = with pkgs; [
    foot
    fuzzel
    waybar
    wl-clipboard
    xwayland-satellite
  ];
}
