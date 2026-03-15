{ config, pkgs, ... }:
{
  xdg.configFile."foot/foot.ini".text = ''
    include=${config.home.homeDirectory}/.config/foot/dank-colors.ini

    shell=fish
    term=xterm-256color
    title=foot
    font=JetBrainsMono Nerd Font:size=20
    letter-spacing=0
    dpi-aware=no
    pad=40x40
    bold-text-in-bright=no

    [scrollback]
    lines=10000

    [cursor]
    style=beam
    blink=yes
    beam-thickness=1.5

    [key-bindings]
    scrollback-up-page=Page_Up
    scrollback-down-page=Page_Down
    clipboard-copy=Control+c
    clipboard-paste=Control+v
    search-start=Control+f
    font-increase=Control+plus Control+equal Control+KP_Add
    font-decrease=Control+minus Control+KP_Subtract
    font-reset=Control+0 Control+KP_0

    [search-bindings]
    cancel=Escape
    find-prev=Shift+F3
    find-next=F3 Control+G
    delete-prev-word=Control+BackSpace

    [text-bindings]
    \x03=Control+Shift+c

    [colors-dark]
    background=000000
    alpha=0.85
  '';

  systemd.user.services.foot-autostart = {
    Unit = {
      After = ["graphical-session.target" "dms.service"];
      Description = "Launch foot on session start";
      PartOf = ["graphical-session.target"];
    };

    Install.WantedBy = ["graphical-session.target"];

    Service = {
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'rm -f $HOME/.config/foot/dank-colors.ini'";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for i in $(seq 1 30); do [ -f $HOME/.config/foot/dank-colors.ini ] && break; sleep 0.5; done; ${pkgs.gnused}/bin/sed -i \"s/^\\[colors\\]$/[colors-dark]/\" $HOME/.config/foot/dank-colors.ini 2>/dev/null; exec ${pkgs.foot}/bin/foot'";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
