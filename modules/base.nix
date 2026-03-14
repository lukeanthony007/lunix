{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.optimise.automatic = true;

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  services.dbus.enable = true;
  security.polkit.enable = true;

  documentation.nixos.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    fd
    git
    jq
    just
    ripgrep
    tree
    vim
    wget
  ];

  system.stateVersion = "25.11";
}
