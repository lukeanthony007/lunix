{
  config,
  lib,
  ...
}:
{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop/audio.nix
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
  services.spice-vdagentd.enable = true;

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      graphics = true;
      memorySize = 8192;
      resolution = {
        x = 1600;
        y = 900;
      };
    };
  };
}
