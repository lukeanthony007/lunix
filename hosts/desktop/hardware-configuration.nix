{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["noatime"];
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-partlabel/EFI";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems."/mnt/Media" = {
    device = "/dev/disk/by-label/Media";
    fsType = "exfat";
    options = ["nofail" "uid=1000" "gid=100"];
  };

  fileSystems."/mnt/Steam" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ext4";
    options = ["nofail"];
  };

  swapDevices = [];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
