{ pkgs, ... }:
let
  # Focus-or-launch: focuses existing window by class, or launches it
  focus-window = pkgs.writeShellScriptBin "focus-window" ''
    FORCE_NEW=false
    if [ "$1" = "-n" ]; then
      FORCE_NEW=true
      shift
    fi
    APP="$1"; shift
    CLASS=$(basename "$APP")

    if [ "$FORCE_NEW" = false ]; then
      ADDR=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r \
        --arg class "$CLASS" \
        '[.[] | select(.class | test($class; "i"))] | first | .address // empty')
      if [ -n "$ADDR" ]; then
        hyprctl dispatch focuswindow "address:$ADDR"
        exit 0
      fi
    fi
    exec "$APP" "$@" &
  '';

  # Zoom using cursor:zoom_factor
  hypr-zoom = pkgs.writeShellScriptBin "hypr-zoom" ''
    CURRENT=$(hyprctl getoption cursor:zoom_factor -j | ${pkgs.jq}/bin/jq -r '.float')
    case "$1" in
      in)
        STEP=''${2:-0.5}
        NEW=$(echo "$CURRENT + $STEP" | ${pkgs.bc}/bin/bc)
        ;;
      out)
        NEW=1.0
        ;;
      *)
        echo "Usage: hypr-zoom in [step] | out"
        exit 1
        ;;
    esac
    hyprctl keyword cursor:zoom_factor "$NEW"
  '';
in
{
  home.packages = [ focus-window hypr-zoom ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;

    settings = {
      "$mod" = "SUPER";

      # --- Monitor ---
      monitor = "DP-1,2560x1440@164.06,0x0,2,vrr,1";

      # --- Environment ---
      env = [
        "GTK_THEME,Adwaita-dark"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "NIXOS_OZONE_WL,1"
      ];

      # --- Input ---
      cursor = {
        hide_on_key_press = true;
        no_warps = true;
      };

      xwayland.force_zero_scaling = true;

      misc = {
        vrr = 1;
        enable_anr_dialog = false;
        disable_hyprland_logo = true;
      };

      # --- Decoration ---
      decoration = {
        blur = {
          enabled = true;
          size = 2;
          passes = 1;
          noise = 0.0;
          contrast = 1.0;
          brightness = 1.0;
          vibrancy = 0.2;
          xray = false;
        };
        shadow = {
          enabled = true;
          range = 40;
          render_power = 4;
          offset = "0 5";
          color = "rgba(00000070)";
        };
      };

      # --- Animations ---
      animations.enabled = true;
      animation = [
        "workspaces, 1, 5, default, slidevert"
        "specialWorkspaceIn, 1, 3, default, slidevert top"
        "specialWorkspaceOut, 1, 3, default, slidevert top"
      ];

      binds.movefocus_cycles_fullscreen = true;

      # --- Keybinds ---
      bind = [
        # App launchers (focus-or-launch)
        "$mod, Return, exec, focus-window foot"
        "$mod, T, exec, focus-window foot"
        "$mod, C, exec, focus-window code --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mod, E, exec, focus-window nautilus"
        "$mod, W, exec, focus-window zen-browser -P Personal"
        "$mod, O, exec, focus-window obsidian --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mod, D, exec, focus-window discord --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto"
        "$mod, B, exec, focus-window obs"
        "$mod, G, exec, focus-window steam --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto"
        "$mod, R, exec, focus-window retroarch"
        "$mod, S, exec, focus-window spotify"

        # Force new window
        "$mod SHIFT, Return, exec, focus-window -n foot"
        "$mod SHIFT, C, exec, focus-window -n code --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mod SHIFT, E, exec, focus-window -n nautilus"
        "$mod SHIFT, W, exec, focus-window -n zen-browser -P Personal"

        # Window management
        "$mod, Tab, workspace, previous"
        "Alt, Tab, movefocus, d"
        "$mod CTRL, Return, fullscreen, 1"
        "$mod ALT, Return, fullscreen, 0"
        "$mod, GRAVE, togglespecialworkspace"
        "$mod SHIFT, GRAVE, movetoworkspace, special"
        "$mod Alt, Space, togglefloating"
        "Alt, F4, killactive"
        "$mod, X, killactive"

        # Workspace navigation
        "$mod, up, workspace, -1"
        "$mod, down, workspace, +1"
        "$mod SHIFT, up, movetoworkspace, -1"
        "$mod SHIFT, down, movetoworkspace, +1"

        # Opacity
        "CTRL $mod, bracketleft, exec, hyprctl dispatch setprop active opacity 0.05-"
        "CTRL $mod, bracketright, exec, hyprctl dispatch setprop active opacity 0.05+"

        # Zoom (mouse buttons)
        ", mouse:276, exec, hypr-zoom in 0.5"
        ", mouse:275, exec, hypr-zoom out"
      ];
    };

    extraConfig = ''
      windowrule {
        name = opacity-spotify
        match:class = Spotify
        match:class = spotify
        opacity = 0.95 override 0.95 override 1.0 override
      }
      windowrule {
        name = opacity-code
        match:class = Code
        match:class = code
        opacity = 0.95 override 0.95 override 1.0 override
      }
      windowrule {
        name = opacity-obsidian
        match:class = obsidian
        opacity = 0.95 override 0.95 override 1.0 override
      }
      windowrule {
        name = opacity-foot
        match:class = foot
        opacity = 0.95 override 0.95 override 1.0 override
      }
      windowrule {
        name = opacity-nautilus
        match:class = org.gnome.Nautilus
        opacity = 0.75 override 0.75 override 1.0 override
      }
      windowrule {
        name = opacity-editors
        match:class = cursor
        match:class = windsurf
        opacity = 0.9 override 0.9 override 1.0 override
      }
      windowrule {
        name = opacity-kitty
        match:class = kitty
        opacity = 0.85 override 0.85 override 1.0 override
      }
      windowrule {
        name = opacity-easyeffects
        match:class = com.github.wwmm.easyeffects
        opacity = 0.9 override 0.9 override 1.0 override
      }
      windowrule {
        name = float-apps
        match:class = automata
        match:class = raia
        match:class = arcana
        float = true
      }
      windowrule {
        name = special-apps
        match:class = automata
        match:class = arcana
        workspace = special:silent
      }
      windowrule {
        name = retroarch-renderunfocused
        match:class = com.libretro.RetroArch
        render_unfocused = on
      }

      # DMS integration
      exec = hyprctl dispatch submap global
      submap = global

      source = dms/execs.conf
      source = dms/general.conf
      source = dms/keybinds.conf
      source = dms/rules.conf
      source = dms/cursor.conf

      # Override DMS animation to scroll vertically
      animation = workspaces, 1, 5, default, slidevert
    '';
  };
}
