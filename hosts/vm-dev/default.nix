{
  config,
  lib,
  ...
}:
{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop/audio.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/fonts.nix
    ../../modules/desktop/niri.nix
    ../../modules/dev/rust.nix
    ../../modules/dev/typescript.nix
    ../../modules/services/docker.nix
    ../../modules/services/ssh.nix
    ../../modules/users/luke.nix
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

  services.greetd.settings.initial_session = {
    command = lib.getExe' config.programs.niri.package "niri-session";
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
        "-device virtio-gpu-gl-pci"
        "-display gtk,gl=on"
        "-audiodev pipewire,id=audio0"
        "-device intel-hda"
        "-device hda-duplex,audiodev=audio0"
      ];
    };
  };
}
