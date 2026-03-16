{ config, pkgs, lib, raia-core-command, raia-shell-package, applianceUser ? "luke", ... }:

#
# Raia Continuity Appliance — bare-metal host profile
#
# Same appliance experience as the VM variant, targeted at real hardware.
# Differences from hosts/appliance:
#   - EFI boot via systemd-boot (not GRUB nodev)
#   - Separate hardware-configuration.nix (generate on target)
#   - No qemuGuest or vmVariant
#   - NetworkManager for WiFi
#   - Redistributable firmware for broad hardware support
#
# Deploy:
#   1. Boot NixOS installer on target machine
#   2. Partition disk (EFI + root)
#   3. nixos-generate-config --root /mnt
#   4. Replace hardware-configuration.nix with generated version
#   5. nixos-install --flake .#appliance-bare
#
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/graphical/audio.nix
    ../../modules/graphical/fonts.nix
    ../../modules/services/raia.nix
  ];

  networking.hostName = "raia-appliance";

  # --- Boot (EFI) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Firmware ---
  hardware.enableRedistributableFirmware = true;

  # --- Networking ---
  networking.networkmanager.enable = true;

  # --- Graphical session ---
  programs.hyprland.enable = true;

  # --- Session launcher (greetd) ---
  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = builtins.toString (pkgs.writeShellScript "appliance-session" ''
        export PATH="${pkgs.hyprland}/bin:${pkgs.foot}/bin:${pkgs.coreutils}/bin:${pkgs.fish}/bin:$PATH"
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"

        mkdir -p "$HOME/.config/hypr/dms"
        for f in execs general keybinds rules cursor colors outputs layout binds windowrules; do
          [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
        done

        mkdir -p "$HOME/.config/foot"
        touch "$HOME/.config/foot/dank-colors.ini"
        touch "$HOME/.config/foot/dank-colors-fixed.ini"

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
  services.getty.autologinUser = null;

  # --- Raia core service ---
  services.raia-core = {
    enable = true;
    coreCommand = raia-core-command;
    shellPackage = raia-shell-package;
  };

  # --- Strip workstation extras ---
  virtualisation.docker.enable = lib.mkForce false;
  xdg.portal.enable = lib.mkForce false;

  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  environment.systemPackages = with pkgs; [
    curl
    foot
    jq
    vim
  ];
}
