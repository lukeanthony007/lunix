{ config, pkgs, lib, raia-core-command, raia-shell-package, applianceUser ? "luke", ... }:

#
# Raia Continuity Appliance — host profile
#
# Stripped to what is needed for shell-driven continuity interaction:
#   boot → raia-core → Hyprland → Foot → raia-shell
#
# Excluded: gaming, productivity apps, cloud-sync, VSCode, Home Assistant,
#           Jellyfin, DMS, browser, general workstation extras.
#
{
  imports = [
    ../../modules/core
    ../../modules/graphical/audio.nix
    ../../modules/graphical/fonts.nix
    ../../modules/services/raia.nix
  ];

  networking.hostName = "raia-appliance";

  # --- Boot ---
  boot.loader.grub = {
    enable = true;
    device = "nodev";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # --- Graphical session ---
  programs.hyprland.enable = true;

  # --- Session launcher (greetd) ---
  # Boots directly into Hyprland for the appliance user.
  # No login prompt — appliance boots to shell.
  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = builtins.toString (pkgs.writeShellScript "appliance-session" ''
        export PATH="${pkgs.hyprland}/bin:${pkgs.foot}/bin:${pkgs.coreutils}/bin:${pkgs.fish}/bin:$PATH"
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"

        # Ensure Hyprland config directories exist
        mkdir -p "$HOME/.config/hypr/dms"
        for f in execs general keybinds rules cursor colors outputs layout binds windowrules; do
          [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
        done

        # Ensure foot config exists
        mkdir -p "$HOME/.config/foot"
        touch "$HOME/.config/foot/dank-colors.ini"
        touch "$HOME/.config/foot/dank-colors-fixed.ini"

        # Try Hyprland; on failure, fall back to Foot on raw TTY
        ${pkgs.hyprland}/bin/start-hyprland || {
          echo ""
          echo "Hyprland failed to start. Falling back to terminal."
          echo "Check: journalctl --user -u hyprland-session"
          echo ""
          exec ${pkgs.fish}/bin/fish
        }
      '');
      user = applianceUser;
    };
  };

  # --- Failure fallback: emergency shell on TTY2 ---
  # If the graphical session fails entirely, the user can switch to
  # TTY2 (Ctrl+Alt+F2) and get a login prompt for debugging.
  services.getty.autologinUser = null;  # TTY requires login (security)

  # --- Raia core service ---
  services.raia-core = {
    enable = true;
    coreCommand = raia-core-command;
    shellPackage = raia-shell-package;
  };

  # --- Appliance-specific: strip workstation extras ---
  # No Docker (not needed for appliance)
  virtualisation.docker.enable = lib.mkForce false;

  # Disable XDG portal (no browser/file picker needed in appliance)
  xdg.portal.enable = lib.mkForce false;

  # Required by Home Manager when useUserPackages is enabled
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Minimal system packages (no general dev tools beyond essentials)
  environment.systemPackages = with pkgs; [
    curl
    foot
    jq
    vim
  ];

  # --- VM support (for validation) ---
  services.qemuGuest.enable = true;

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      diskSize = 8192;
      graphics = true;
      memorySize = 8192;
      qemu.options = [
        "-vga none"
        "-device virtio-gpu-pci"
        "-display gtk"
        "-audiodev pipewire,id=audio0"
        "-device intel-hda"
        "-device hda-duplex,audiodev=audio0"
      ];
    };
  };
}
