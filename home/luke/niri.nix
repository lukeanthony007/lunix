{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    git
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

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=11";
        pad = "8x8";
      };
      colors-dark = {
        alpha = "0.92";
        background = "1a1b26";
        foreground = "c0caf5";
        regular0 = "15161e";
        regular1 = "f7768e";
        regular2 = "9ece6a";
        regular3 = "e0af68";
        regular4 = "7aa2f7";
        regular5 = "bb9af7";
        regular6 = "7dcfff";
        regular7 = "a9b1d6";
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "7dcfff";
        bright7 = "c0caf5";
      };
    };
  };

  programs.niri.settings = {
    environment."NIXOS_OZONE_WL" = "1";
  };

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    niri = {
      enableKeybinds = true;
      enableSpawn = false;
      includes.enable = true;
    };
    settings = builtins.fromJSON (builtins.readFile ./dms-settings.json);
  };

  programs.dsearch = {
    enable = true;
  };

  systemd.user.services.clone-wallpapers = {
    Unit = {
      After = ["network-online.target"];
      Description = "Clone wallpapers repo if missing";
    };

    Install.WantedBy = ["default.target"];

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d $HOME/Pictures/Wallpapers/.git ]; then rm -rf $HOME/Pictures/Wallpapers; ${pkgs.git}/bin/git clone --depth 1 https://github.com/lukeanthony007/Wallpapers.git $HOME/Pictures/Wallpapers; fi'";
    };
  };

  systemd.user.services.random-wallpaper = let
    script = pkgs.writeShellScript "random-wallpaper" ''
      dir="$HOME/Pictures/Wallpapers"
      [ -d "$dir" ] || exit 0
      wallpaper=$(${pkgs.findutils}/bin/find "$dir" -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.avif' -o -name '*.webp' \) | ${pkgs.coreutils}/bin/shuf -n 1)
      [ -n "$wallpaper" ] || exit 0
      exec dms ipc wallpaper set "$wallpaper"
    '';
  in {
    Unit = {
      After = ["dms.service" "clone-wallpapers.service"];
      Description = "Set random wallpaper via DMS on session start";
    };

    Install.WantedBy = ["dms.service"];

    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${script}";
    };
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
}
