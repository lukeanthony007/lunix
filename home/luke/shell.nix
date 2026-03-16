{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    ripgrep
    uv
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "foot";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    OZONE_PLATFORM = "wayland";
    NATIVE_WAYLAND = "1";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
  ];

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
    '';

    shellAbbrs = {
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
      gco = "git checkout";

      ls = "eza";
      ll = "eza -la";
      lt = "eza --tree --level=2";
      cat = "bat";

      hms = "home-manager switch --flake .";
    };

    plugins = [
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
      { name = "done"; src = pkgs.fishPlugins.done.src; }
      { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer.src; }
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # silence the verbose loading messages
    config.global.hide_env_diff = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = false; # fzf-fish plugin handles this
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile."starship.toml".source = ./config/starship.toml;
}
