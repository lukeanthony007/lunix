{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    foot
    git
    inputs.zen-browser.packages.${pkgs.system}.default
    gnome-text-editor
    nautilus
    nerd-fonts.jetbrains-mono
    pavucontrol
    retroarch
    spotify
    starship
    vscode
    wl-clipboard
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

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

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      starship init fish | source
    '';
  };

  xdg.configFile."starship.toml".source = ./starship.toml;

  xdg.configFile."nvim/lua/plugins/transparent.lua".text = ''
    return {
      {
        "xiyaowong/transparent.nvim",
        lazy = false,
        config = function()
          require("transparent").setup({
            extra_groups = { "StatusLine", "StatusLineNC" },
          })
          require("transparent").toggle(true)
          local function fix_stl()
            vim.api.nvim_set_hl(0, "StatusLine", { link = "Normal" })
            vim.api.nvim_set_hl(0, "StatusLineNC", { link = "Normal" })
          end
          vim.defer_fn(fix_stl, 1000)
          vim.api.nvim_create_autocmd({"BufEnter", "ColorScheme"}, {
            callback = function() vim.defer_fn(fix_stl, 100) end,
          })
        end,
      },
    }
  '';

  xdg.configFile."foot/foot.ini".text = ''
    include=/home/luke/.config/foot/dank-colors.ini

    shell=fish
    term=xterm-256color
    title=foot
    font=JetBrainsMono Nerd Font:size=20
    letter-spacing=0
    dpi-aware=no
    pad=40x40
    bold-text-in-bright=no

    [scrollback]
    lines=10000

    [cursor]
    style=beam
    blink=yes
    beam-thickness=1.5

    [key-bindings]
    scrollback-up-page=Page_Up
    scrollback-down-page=Page_Down
    clipboard-copy=Control+c
    clipboard-paste=Control+v
    search-start=Control+f
    font-increase=Control+plus Control+equal Control+KP_Add
    font-decrease=Control+minus Control+KP_Subtract
    font-reset=Control+0 Control+KP_0

    [search-bindings]
    cancel=Escape
    find-prev=Shift+F3
    find-next=F3 Control+G
    delete-prev-word=Control+BackSpace

    [text-bindings]
    \x03=Control+Shift+c

    [colors-dark]
    background=000000
    alpha=0.85
  '';

  programs.niri.settings = {
    layer-rules = [
      {
        matches = [{ namespace = "^quickshell"; }];
        opacity = 0.8;
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
      }
      {
        matches = [{ app-id = "^foot$"; }];
        opacity = 0.95;
        draw-border-with-background = false;
        default-column-width.proportion = 1.0;
      }
      {
        matches = [{ app-id = "^org\\.gnome\\.Nautilus$"; }];
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
        matches = [{ app-id = "^kitty$"; }];
        opacity = 0.85;
      }
    ];

    binds = let
      spawn = args: { action.spawn = args; };
    in {
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

      "Print".action.screenshot = {};
      "Ctrl+Print".action.screenshot-screen = {};
      "Alt+Print".action.screenshot-window = {};
    };
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

  systemd.user.services.clone-nvchad = {
    Unit = {
      Wants = ["network-online.target"];
      After = ["network-online.target"];
      Description = "Clone NvChad config if missing";
    };

    Install.WantedBy = ["default.target"];

    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d $HOME/.config/nvim/.git ]; then rm -rf $HOME/.config/nvim; ${pkgs.git}/bin/git clone --depth 1 https://github.com/NvChad/starter $HOME/.config/nvim; fi'";
    };
  };

  systemd.user.services.clone-wallpapers = {
    Unit = {
      Wants = ["network-online.target"];
      After = ["network-online.target"];
      Description = "Clone wallpapers repo if missing";
    };

    Install.WantedBy = ["default.target"];

    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d $HOME/Pictures/Wallpapers/.git ]; then rm -rf $HOME/Pictures/Wallpapers; ${pkgs.git}/bin/git clone --depth 1 https://github.com/lukeanthony007/Wallpapers.git $HOME/Pictures/Wallpapers; fi'";
    };
  };

  systemd.user.services.random-wallpaper = let
    script = pkgs.writeShellScript "random-wallpaper" ''
      dir="$HOME/Pictures/Wallpapers"
      [ -d "$dir" ] || exit 0
      wallpaper=$(${pkgs.findutils}/bin/find "$dir" -type f -size +100k \( -name '*.jpg' -o -name '*.png' -o -name '*.avif' -o -name '*.webp' \) | ${pkgs.coreutils}/bin/shuf -n 1)
      [ -n "$wallpaper" ] || exit 0

      # Write wallpaper to DMS session.json before DMS reads it
      session_dir="$HOME/.local/state/DankMaterialShell"
      ${pkgs.coreutils}/bin/mkdir -p "$session_dir"
      session_file="$session_dir/session.json"
      if [ -f "$session_file" ]; then
        ${pkgs.jq}/bin/jq --arg wp "$wallpaper" '.wallpaperPath = $wp | .wallpaperPathDark = $wp | .wallpaperPathLight = $wp' "$session_file" > "$session_file.tmp" && mv "$session_file.tmp" "$session_file"
      else
        echo "{\"wallpaperPath\": \"$wallpaper\", \"wallpaperPathDark\": \"$wallpaper\", \"wallpaperPathLight\": \"$wallpaper\"}" > "$session_file"
      fi
    '';
  in {
    Unit = {
      Before = ["dms.service"];
      Description = "Pre-select random wallpaper before DMS starts";
    };

    Install.WantedBy = ["graphical-session.target"];

    Service = {
      Type = "oneshot";
      ExecStart = "${script}";
    };
  };

  systemd.user.services.foot-autostart = {
    Unit = {
      After = ["graphical-session.target" "dms.service"];
      Description = "Launch foot on session start";
      PartOf = ["graphical-session.target"];
    };

    Install.WantedBy = ["graphical-session.target"];

    Service = {
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'rm -f $HOME/.config/foot/dank-colors.ini'";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in $(seq 1 30); do [ -f $HOME/.config/foot/dank-colors.ini ] && break; sleep 0.5; done; exec ${pkgs.foot}/bin/foot'";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
