{ ... }:
{
  programs.niri.settings = {
    hotkey-overlay.skip-at-startup = true;

    layer-rules = [
      {
        matches = [{ namespace = "^quickshell"; }];
      }
    ];

    environment = {
      "NIXOS_OZONE_WL" = "1";
      "GTK_THEME" = "Adwaita-dark";
    };

    input.keyboard.xkb.layout = "us";

    layout = {
      gaps = 10;
      border.enable = false;
      focus-ring.enable = false;
    };

    prefer-no-csd = true;

    window-rules = [
      {
        geometry-corner-radius = let r = 12.0; in { bottom-left = r; bottom-right = r; top-left = r; top-right = r; };
        clip-to-geometry = true;
        default-column-width.proportion = 1.0;
        draw-border-with-background = false;
      }
      {
        matches = [{ app-id = "^foot$"; }];
        opacity = 0.95;
        draw-border-with-background = false;
        default-column-width.proportion = 1.0;
      }
      {
        matches = [{ app-id = "^[Cc]ode$"; }];
        opacity = 0.95;
      }
      {
        matches = [{ app-id = "^Spotify$"; } { app-id = "^spotify$"; }];
        opacity = 0.95;
      }
      {
        matches = [{ app-id = "^obsidian$"; }];
        opacity = 0.95;
      }
      {
        matches = [{ app-id = "^dev\\.lunix\\.bootstrap$"; }];
        open-fullscreen = true;
      }
    ];

    binds = {
      "Mod+Return".action.spawn = ["foot"];
      "Mod+T".action.spawn = ["foot"];
      "Alt+F4".action.close-window = {};

      "Mod+Left".action.focus-column-left = {};
      "Mod+Right".action.focus-column-right = {};
      "Mod+Up".action.focus-workspace-up = {};
      "Mod+Down".action.focus-workspace-down = {};

      "Mod+Shift+Left".action.move-column-left = {};
      "Mod+Shift+Right".action.move-column-right = {};
      "Mod+Shift+Up".action.move-window-to-workspace-up = {};
      "Mod+Shift+Down".action.move-window-to-workspace-down = {};

      "Mod+Tab".action.focus-workspace-previous = {};
      "Alt+Tab".action.focus-window-down-or-column-right = {};

      "Mod+Ctrl+Return".action.maximize-column = {};
      "Mod+Alt+Return".action.fullscreen-window = {};
      "Mod+Alt+Space".action.toggle-window-floating = {};

      "Mod+Grave".action.toggle-overview = {};

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";

      "Mod+WheelScrollDown".action.focus-workspace-down = {};
      "Mod+WheelScrollUp".action.focus-workspace-up = {};
      "Mod+Shift+WheelScrollDown".action.focus-column-right = {};
      "Mod+Shift+WheelScrollUp".action.focus-column-left = {};
      "Shift+WheelScrollDown".action.focus-column-right = {};
      "Shift+WheelScrollUp".action.focus-column-left = {};

      "Mod+D".action.spawn = ["dms" "ipc" "spotlight" "toggle"];

      "Print".action.screenshot = {};
      "Ctrl+Print".action.screenshot-screen = {};
      "Alt+Print".action.screenshot-window = {};
    };
  };
}
