{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji
    source-code-pro
  ];
}
