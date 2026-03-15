{ pkgs, lib, ... }:
{
  # Nix-built QuickShell needs Arch's GL stack (Nix Mesa has no DRI drivers)
  systemd.user.services.dms.Service.Environment = [
    "LIBGL_DRIVERS_PATH=/usr/lib/dri"
    "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
    "LD_LIBRARY_PATH=/usr/lib"
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    niri = {
      enableKeybinds = true;
      enableSpawn = false;
    };
    settings = builtins.fromJSON (builtins.readFile ../config/dms-settings.json);
    session = {
      isLightMode = false;
    };
    clipboardSettings = {
      maxHistory = 25;
      maxEntrySize = 5242880;
      autoClearDays = 1;
      clearAtStartup = true;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };
  };

  programs.dsearch = {
    enable = true;
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
      # Skip on first boot — bootstrap handles wallpaper selection
      ConditionPathExists = "%h/.local/state/bootstrap-done";
    };

    # Disabled — bootstrap handles wallpaper selection now
    # Install.WantedBy = ["graphical-session.target"];

    Service = {
      Type = "oneshot";
      ExecStart = "${script}";
    };
  };
}
