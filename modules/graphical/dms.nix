{ ... }:
{
  # System-level DMS: greeter config. User-level runtime config is in home/luke/desktop/dms.nix.
  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
    greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/luke";
    };
  };
}
