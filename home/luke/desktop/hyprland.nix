{ pkgs, lib, ... }:
let
  # Kill active window
  hypr-kill = pkgs.writeShellScriptBin "hypr-kill" ''
    hyprctl dispatch killactive
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

  # Create stub configs so Hyprland can parse source= lines before DMS/custom files exist
  home.activation.hyprConfigStubs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.config/hypr/dms"
    for f in colors outputs layout cursor binds execs general keybinds rules windowrules; do
      [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
    done
    mkdir -p "$HOME/.config/hypr/custom"
    for f in general cursor binds rules; do
      [ -f "$HOME/.config/hypr/custom/$f.conf" ] || touch "$HOME/.config/hypr/custom/$f.conf"
    done
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # use system Hyprland on Arch, not Nix
    systemd.enable = true;
    settings = {};

    extraConfig = ''
      exec-once = dbus-update-activation-environment --systemd --all
      exec-once = systemctl --user start hyprland-session.target

      exec = hyprctl dispatch submap global
      submap = global

      # DMS managed (loaded first)
      source = ~/.config/hypr/dms/colors.conf
      source = ~/.config/hypr/dms/outputs.conf
      source = ~/.config/hypr/dms/layout.conf
      source = ~/.config/hypr/dms/cursor.conf
      source = ~/.config/hypr/dms/binds.conf

      # Custom overrides (loaded second — takes precedence)
      source = ~/.config/hypr/custom/general.conf
      source = ~/.config/hypr/custom/cursor.conf
      source = ~/.config/hypr/custom/binds.conf
      source = ~/.config/hypr/custom/rules.conf
    '';
  };

  # --- Custom override configs ---
  # These are sourced after DMS configs, so they take precedence.

  home.file.".config/hypr/custom/general.conf".text = ''
    # Environment
    env = QT_QPA_PLATFORMTHEME,qt6ct
    env = NIXOS_OZONE_WL,1

    # General
    general {
      gaps_in = 10
      gaps_out = 15
      border_size = 0
      layout = dwindle
    }

    # Decoration
    decoration {
      rounding = 12
      blur {
        enabled = true
        size = 2
        passes = 1
        noise = 0.0
        contrast = 1.0
        brightness = 1.0
        vibrancy = 0.2
        xray = false
      }
      shadow {
        enabled = true
        range = 40
        render_power = 4
        offset = 0 5
        color = rgba(00000070)
      }
    }

    # Animations
    animations {
      enabled = true
    }
    animation = workspaces, 1, 5, default, slidevert
    animation = specialWorkspaceIn, 1, 3, default, slidevert top
    animation = specialWorkspaceOut, 1, 3, default, slidevert top

    # Misc
    misc {
      vrr = 1
      enable_anr_dialog = false
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }

    # Layout
    dwindle {
      preserve_split = true
    }
    master {
      mfact = 0.5
    }
    binds {
      movefocus_cycles_fullscreen = true
    }
    xwayland {
      force_zero_scaling = true
    }
  '';

  home.file.".config/hypr/custom/cursor.conf".text = ''
    cursor {
      hide_on_key_press = true
      no_warps = true
    }
  '';

  home.file.".config/hypr/custom/binds.conf".text = ''
    $mod = SUPER

    # Unbind DMS defaults that conflict with custom binds
    unbind = SUPER, mouse_down
    unbind = SUPER, mouse_up
    unbind = SUPER, T
    unbind = SUPER, TAB
    unbind = SUPER, X
    unbind = SUPER, W
    unbind = SUPER, R
    unbind = SUPER, up
    unbind = SUPER, down
    unbind = SUPER SHIFT, E
    unbind = SUPER SHIFT, W
    unbind = SUPER SHIFT, up
    unbind = SUPER SHIFT, down

    # DMS spotlight (tap super key)
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
    bind = $mod SHIFT, W, exec, focus-window -n zen-beta -P Personal

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

    # Opacity
    bind = CTRL $mod, bracketleft, exec, hyprctl dispatch setprop active opacity 0.05-
    bind = CTRL $mod, bracketright, exec, hyprctl dispatch setprop active opacity 0.05+

    # Scroll workspaces (all, not just active)
    bind = $mod, mouse_down, workspace, -1
    bind = $mod, mouse_up, workspace, +1

    # Move window with scroll
    bind = $mod SHIFT, mouse_down, movetoworkspace, -1
    bind = $mod SHIFT, mouse_up, movetoworkspace, +1

    # Zoom (mouse buttons)
    bind = , mouse:276, exec, hypr-zoom in 0.5
    bind = , mouse:275, exec, hypr-zoom out
  '';

  home.file.".config/hypr/custom/rules.conf".text = ''
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
      opacity = 0.95 override 0.95 override 1.0 override
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
  '';
}
