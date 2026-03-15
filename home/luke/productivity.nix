{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    deluge-gtk
    discord
    obsidian
    signal-desktop
    zoom-us
  ];

  programs.spicetify = {
    enable = true;
    enabledExtensions = with inputs.spicetify-nix.legacyPackages.${pkgs.system}.extensions; [
      adblock
    ];
  };
}
