{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    wl-clipboard
  ];

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  programs.foot.enable = true;
  programs.fuzzel.enable = true;

  programs.niri.settings = {
    environment."NIXOS_OZONE_WL" = "1";
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar.layer = "top";
  };

  systemd.user.services.foot-autostart = {
    Unit = {
      After = ["graphical-session.target"];
      Description = "Launch foot on session start";
      PartOf = ["graphical-session.target"];
    };

    Install.WantedBy = ["graphical-session.target"];

    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep 3; exec ${pkgs.foot}/bin/foot'";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  services.mako.enable = true;
}
