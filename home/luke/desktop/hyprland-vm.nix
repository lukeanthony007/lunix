{ ... }:
{
  # Override $mod to CTRL in the VM so host Super key isn't intercepted
  wayland.windowManager.hyprland.settings."$mod" = "CTRL";
}
