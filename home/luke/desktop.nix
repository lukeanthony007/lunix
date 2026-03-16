{ inputs, pkgs, ... }:
{
  imports = [
    ./bootstrap.nix
    ./cloud-sync.nix
    ./desktop/dms.nix
    ./desktop/foot.nix
    ./desktop/hyprland.nix
    ./desktop/settings.nix
    ./desktop/vscode.nix
    ./desktop/zen.nix
  ];

  home.packages = with pkgs; [
    btop
    bun
    claude-code
    codex
    fastfetch
    imv
    gnome-text-editor
    mpv
    nautilus
    nerd-fonts.jetbrains-mono
    p7zip
    pavucontrol
    qemu
    unzip
    vscode
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  services.bootstrap.enable = true;

  services.cloud-sync = {
    enable = true;
    provider = "b2";
    remoteName = "cloud";
    directories = [
      { remote = "Documents"; local = "Documents"; }
      { remote = "Pictures";  local = "Pictures"; }
    ];
  };
}
