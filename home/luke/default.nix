{ ... }:
{
  imports = [
    ./editors.nix
    ./git.nix
    ./niri.nix
    ./shell.nix
  ];

  home.username = "luke";
  home.homeDirectory = "/home/luke";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
