{ config, lib, pkgs, ... }:

let
  cfg = config.services.bootstrap;

  qsConfigDir = ./desktop/bootstrap-qs;
  bootstrapScript = "${qsConfigDir}/bootstrap.sh";
  statusFile = ".local/state/bootstrap-status.json";

  bootstrapApp = pkgs.writeShellScriptBin "lu-nix-bootstrap" ''
    export PATH="${lib.makeBinPath (with pkgs; [ coreutils findutils gawk git iputils jq ])}:$PATH"

    # Check marker
    [ -f "$HOME/.local/state/bootstrap-done" ] && [ "''${1:-}" != "--force" ] && exit 0

    # Suppress DMS first-launch greeter and changelog (we handle onboarding ourselves)
    mkdir -p "$HOME/.config/DankMaterialShell"
    touch "$HOME/.config/DankMaterialShell/.firstlaunch"
    # Create changelog markers for all known versions
    for v in 1.0 1.1 1.2 1.3 1.4 1.5 2.0; do
      touch "$HOME/.config/DankMaterialShell/.changelog-$v"
    done

    # Hide unwanted apps from DMS launcher
    SESSION_DIR="$HOME/.local/state/DankMaterialShell"
    SESSION_FILE="$SESSION_DIR/session.json"
    mkdir -p "$SESSION_DIR"
    if [ -f "$SESSION_FILE" ]; then
      ${pkgs.jq}/bin/jq '.hiddenApps = ["nvim","vim","gvim","btop","foot-server","footclient","ikhal"]' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"
    else
      echo '{"hiddenApps":["nvim","vim","gvim","btop","foot-server","footclient","ikhal"]}' > "$SESSION_FILE"
    fi

    # Create initial status file so QML can find it
    mkdir -p "$HOME/.local/state"
    echo '{"task0state":"running","task0desc":"Starting...","task1state":"pending","task1desc":"Editor configuration","task2state":"pending","task2desc":"Cloud storage","progress":0.0,"status":"Starting...","wallpapers":[]}' > "$HOME/${statusFile}"

    # Ensure niri has a valid config (home-manager may not have written it yet)
    if ! ${pkgs.niri}/bin/niri validate 2>/dev/null; then
      mkdir -p "$HOME/.config/niri"
      echo 'hotkey-overlay { skip-at-startup }' > "$HOME/.config/niri/config.kdl"
      ${pkgs.niri}/bin/niri msg action reload-config 2>/dev/null || true
    fi

    # Run bootstrap tasks in background
    sh "${bootstrapScript}" &

    # Start quickshell (blocks until user quits)
    ${pkgs.quickshell}/bin/quickshell -p "${qsConfigDir}"

    # Reload niri config now that home-manager and DMS have written their includes
    ${pkgs.niri}/bin/niri msg action reload-config 2>/dev/null || true
  '';

  lazyWallpapers = pkgs.writeShellScript "lazy-wallpapers" ''
    dir="$HOME/Pictures/Wallpapers"
    [ -d "$dir/.git" ] || exit 0
    cd "$dir"

    # Get all folders sorted newest-first, download one at a time
    FOLDERS=$(${pkgs.git}/bin/git ls-tree -d --name-only HEAD 2>/dev/null | grep -v '^\.' | sort -r)

    for folder in $FOLDERS; do
      echo "Fetching: $folder"
      ${pkgs.git}/bin/git sparse-checkout add "$folder" 2>/dev/null || true
    done
  '';
in
{
  options.services.bootstrap = {
    enable = lib.mkEnableOption "first-login welcome screen";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ bootstrapApp ];

    systemd.user.services.bootstrap = {
      Unit = {
        Description = "lu-nix first-login welcome screen";
        After = [ "graphical-session.target" ];
        ConditionPathExists = "!%h/.local/state/bootstrap-done";
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "oneshot";
        ExecStart = "${bootstrapApp}/bin/lu-nix-bootstrap";
        Environment = [
          "WAYLAND_DISPLAY=wayland-1"
          "XDG_RUNTIME_DIR=%t"
          "LIBGL_DRIVERS_PATH=/usr/lib/dri"
          "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
          "LD_LIBRARY_PATH=/usr/lib"
        ];
        TimeoutStartSec = "10min";
      };
    };

    # Make DMS and foot wait for bootstrap to finish
    systemd.user.services.dms = {
      Unit.After = [ "bootstrap.service" ];
    };
    systemd.user.services.foot-autostart = {
      Unit.After = [ "bootstrap.service" ];
    };

    systemd.user.services.lazy-wallpapers = {
      Unit = {
        Description = "Download remaining wallpaper folders";
        After = [ "dms.service" "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "oneshot";
        ExecStart = "${lazyWallpapers}";
      };
    };
  };
}
