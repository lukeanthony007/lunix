{ inputs, pkgs, ... }:
let
  # The VS Code extension resolves `claude` on PATH and tries to import() it
  # as a Node.js ES module. The standard Nix wrapper is a bash script, which
  # causes a SyntaxError. This derivation replaces bin/claude with a thin JS
  # shim that sets the same env vars and then loads the real entrypoint.
  claude-code-vscode = pkgs.symlinkJoin {
    name = "claude-code-vscode-${pkgs.claude-code.version}";
    paths = [ pkgs.claude-code ];
    postBuild = ''
      rm $out/bin/claude $out/bin/.claude-wrapped
      cat > $out/bin/claude << 'SHIM'
#!/usr/bin/env node
process.env.DISABLE_AUTOUPDATER = '1';
process.env.FORCE_AUTOUPDATE_PLUGINS ??= '1';
process.env.DISABLE_INSTALLATION_CHECKS = '1';
delete process.env.DEV;
SHIM
      cat >> $out/bin/claude <<EOF
const bins = ['${pkgs.socat}/bin', '${pkgs.bubblewrap}/bin', '${pkgs.procps}/bin'];
process.env.PATH = [...bins, process.env.PATH].filter(Boolean).join(':');
await import('${pkgs.claude-code}/lib/node_modules/@anthropic-ai/claude-code/cli.js');
EOF
      chmod +x $out/bin/claude
    '';
  };
in
{
  imports = [
    ./bootstrap.nix
    ./cloud-sync.nix
    ./desktop/dms.nix
    ./desktop/foot.nix
    ./desktop/hyprland.nix
    ./desktop/qt.nix
    ./desktop/settings.nix
    ./desktop/spicetify.nix
    ./desktop/vscode.nix
    ./desktop/zen.nix
  ];

  home.packages = with pkgs; [
    btop
    bun
    claude-code-vscode
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
