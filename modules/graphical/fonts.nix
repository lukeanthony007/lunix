{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    inter
    liberation_ttf
    material-symbols
    noto-fonts
    noto-fonts-color-emoji
    source-code-pro
  ];
}
