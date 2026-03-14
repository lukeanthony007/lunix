{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
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

  networking.hostName = "desktop";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  # AMD RX 5700 XT (RDNA 1)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];

  # Intel AX210 WiFi + Bluetooth
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Firmware
  hardware.enableRedistributableFirmware = true;

  # Logitech C922 webcam
  hardware.logitech.wireless.enable = false;

  services.qemuGuest.enable = false;
}
