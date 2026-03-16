{ pkgs, lib, ... }:
let
  # Kill active window — pkill apps that ignore WM close (e.g. Spotify)
  hypr-kill = pkgs.writeShellScriptBin "hypr-kill" ''
    CLASS=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')
    case "$CLASS" in
      Spotify|spotify)
        pkill -x spotify ;;
      *)
        hyprctl dispatch killactive ;;
    esac
  '';

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
  home.packages = [ focus-window hypr-kill hypr-zoom ];

  # Create DMS stub configs so Hyprland can parse source= lines before DMS runs
  home.activation.hyprDmsStubs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.config/hypr/dms"
    for f in execs general keybinds rules cursor; do
      [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
    done
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # use system Hyprland on Arch, not Nix
    systemd.enable = true;

    settings = {
      "$mod" = "SUPER";

      # --- Monitor ---
      monitor = [
        "DP-1,2560x1440@164.06,0x0,2,vrr,1"
        ",preferred,auto,auto"
      ];

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
        disable_splash_rendering = true;
      };

      dwindle.preserve_split = true;
      master.mfact = 0.5;

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

      binds.movefocus_cycles_fullscreen = true;
    };

    extraConfig = ''
      exec = hyprctl dispatch submap global
      submap = global
      $mod = SUPER

      # --- Animations ---
      animation = workspaces, 1, 5, default, slidevert
      animation = specialWorkspaceIn, 1, 3, default, slidevert top
      animation = specialWorkspaceOut, 1, 3, default, slidevert top

      # --- Keybinds ---
      bindr = $mod, Super_L, exec, dms ipc call spotlight toggle
      bindr = $mod, Super_R, exec, dms ipc call spotlight toggle

      # App launchers (focus-or-launch)
      bind = $mod, Return, exec, focus-window foot
      bind = $mod, T, exec, focus-window foot
      bind = $mod, C, exec, focus-window code --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland
      bind = $mod, E, exec, focus-window nautilus
      bind = $mod, W, exec, focus-window zen-beta -P Personal
      bind = $mod, O, exec, focus-window obsidian --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland
      bind = $mod, D, exec, focus-window discord --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto
      bind = $mod, G, exec, focus-window steam --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto
      bind = $mod, R, exec, focus-window retroarch
      bind = $mod, S, exec, focus-window spotify

      # Force new window
      bind = $mod SHIFT, Return, exec, focus-window -n foot
      bind = $mod SHIFT, C, exec, focus-window -n code --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland
      bind = $mod SHIFT, E, exec, focus-window -n nautilus
      bind = $mod SHIFT, W, exec, focus-window -n zen-browser -P Personal

      # Window management
      bind = $mod, Tab, workspace, previous
      bind = Alt, Tab, movefocus, d
      bind = $mod CTRL, Return, fullscreen, 1
      bind = $mod ALT, Return, fullscreen, 0
      bind = $mod, GRAVE, togglespecialworkspace
      bind = $mod SHIFT, GRAVE, movetoworkspace, special
      bind = $mod Alt, Space, togglefloating
      bind = Alt, F4, exec, hypr-kill
      bind = $mod, X, exec, hypr-kill

      # Workspace navigation
      bind = $mod, up, workspace, -1
      bind = $mod, down, workspace, +1
      bind = $mod SHIFT, up, movetoworkspace, -1
      bind = $mod SHIFT, down, movetoworkspace, +1
      # mouse_up/mouse_down and numbered workspaces are in dms/keybinds.conf

      # Opacity
      bind = CTRL $mod, bracketleft, exec, hyprctl dispatch setprop active opacity 0.05-
      bind = CTRL $mod, bracketright, exec, hyprctl dispatch setprop active opacity 0.05+

      # Zoom (mouse buttons)
      bind = , mouse:276, exec, hypr-zoom in 0.5
      bind = , mouse:275, exec, hypr-zoom out

      # --- Window Rules ---
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

      source = ~/.config/hypr/dms/execs.conf
      source = ~/.config/hypr/dms/general.conf
      source = ~/.config/hypr/dms/keybinds.conf
      source = ~/.config/hypr/dms/rules.conf
      source = ~/.config/hypr/dms/cursor.conf

      # Override DMS animation to scroll vertically
      animation = workspaces, 1, 5, default, slidevert
    '';
  };
}
