{ ... }:
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
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";
}
