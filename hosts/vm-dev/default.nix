{ pkgs, ... }:
{
  imports = [
    ../../modules
  ];

  networking.hostName = "vm-dev";

  boot.loader.grub = {
    enable = true;
    device = "nodev";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  programs.hyprland.enable = true;

  services.greetd.settings.initial_session = {
    command = builtins.toString (pkgs.writeShellScript "hyprland-session" ''
      export PATH="${pkgs.hyprland}/bin:${pkgs.foot}/bin:${pkgs.coreutils}/bin:$PATH"
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      mkdir -p "$HOME/.config/hypr/dms"
      for f in execs general keybinds rules cursor; do
        [ -f "$HOME/.config/hypr/dms/$f.conf" ] || touch "$HOME/.config/hypr/dms/$f.conf"
      done
      touch "$HOME/.config/foot/dank-colors.ini"
      exec ${pkgs.hyprland}/bin/start-hyprland
    '');
    user = "luke";
  };

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
