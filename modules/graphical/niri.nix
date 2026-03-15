{ pkgs, ... }:
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
      user = "greeter";
    };
  };

  environment.systemPackages = with pkgs; [
    foot
    wl-clipboard
    xwayland-satellite
  ];
}
