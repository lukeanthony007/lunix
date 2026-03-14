{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.bash.enable = true;
}
