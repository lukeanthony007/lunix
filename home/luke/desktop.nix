{ inputs, pkgs, ... }:
{
  imports = [
    ./bootstrap.nix
    ./cloud-sync.nix
    ./desktop/dms.nix
    ./desktop/foot.nix
    ./desktop/hyprland.nix
    ./desktop/qt.nix
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
    foot
    imv
    gnome-text-editor
    mpv
    adw-gtk3
    nerd-fonts.jetbrains-mono
    p7zip
    pavucontrol
    qemu
    unzip
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "video/mp4" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "application/toml" = "code.desktop";
      "text/x-sh" = "code.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
    };
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
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  services.bootstrap.enable = true;

  services.cloud-sync = {
    enable = true;
    provider = "gdrive";
    remoteName = "gdrive";
    directories = [
      { remote = "Documents"; local = "Documents"; }
      { remote = "Pictures";  local = "Pictures"; }
      { remote = "Desktop";   local = "Desktop"; }
      { remote = "Music";     local = "Music"; }
      { remote = "Downloads"; local = "Downloads"; }
      { remote = "Data";      local = "Data"; }
    ];
  };
}
