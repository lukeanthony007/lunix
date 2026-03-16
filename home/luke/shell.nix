{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "foot";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    OZONE_PLATFORM = "wayland";
    NATIVE_WAYLAND = "1";
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    functions.fish_prompt = ''
      # Override pure theme's fish_prompt to fix cursor position in VSCode/Cursor
      set --local exit_code $status

      _pure_print_prompt_rows
      _pure_place_iterm2_prompt_mark
      echo -e -n (_pure_prompt $exit_code)
      echo -e -n (_pure_prompt_ending)

      set _pure_fresh_session false
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile."starship.toml".source = ./config/starship.toml;
}
