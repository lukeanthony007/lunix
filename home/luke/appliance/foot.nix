{ config, pkgs, ... }:

#
# Appliance Foot terminal config
#
# Launches raia-shell on startup. Waits for raia-core readiness.
# Falls back to a diagnostic Fish prompt if shell or core fails.
#
let
  # Script that waits for raia-core and launches raia-shell.
  # On shell exit or crash, loops back and relaunches (appliance stays alive).
  raia-shell-launcher = pkgs.writeShellScript "raia-shell-launcher" ''
    RAIA_HOME="$HOME/.raia"
    CORE_URL="http://127.0.0.1:4111"

    while true; do
      clear

      # --- Check provisioning ---
      if [ ! -f "$RAIA_HOME/.provisioned" ]; then
        echo ""
        echo "  Raia appliance is not provisioned."
        echo ""
        echo "  Run:  raia-provision"
        echo ""
        echo "  Then restart: sudo systemctl restart raia-core"
        echo ""
        exec ${pkgs.fish}/bin/fish
      fi

      # --- Wait for core readiness ---
      echo "waiting for raia-core..."
      TIMEOUT=60
      ELAPSED=0
      while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
        STATUS=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" "$CORE_URL/health/ready" 2>/dev/null || echo "000")
        if [ "$STATUS" = "200" ]; then
          break
        fi

        # Show progress
        if [ "$((ELAPSED % 5))" = "0" ] && [ "$ELAPSED" -gt 0 ]; then
          echo "  still waiting... (''${ELAPSED}s, status=$STATUS)"
        fi

        sleep 1
        ELAPSED=$((ELAPSED + 1))
      done

      if [ "$STATUS" != "200" ]; then
        echo ""
        echo "  raia-core did not become ready after ''${TIMEOUT}s"
        echo ""
        echo "  Check service status:  systemctl status raia-core"
        echo "  View logs:             journalctl -u raia-core -f"
        echo "  Retry:                 exit this shell to retry"
        echo ""
        echo "  Dropping to diagnostic shell."
        echo ""
        ${pkgs.fish}/bin/fish
        # After fish exits, loop restarts — re-check core
        continue
      fi

      # --- Launch raia-shell ---
      raia-shell
      EXIT_CODE=$?

      # Shell exited — brief pause then relaunch
      if [ "$EXIT_CODE" -eq 0 ]; then
        echo ""
        echo "  shell exited — relaunching in 2s (Ctrl+C for fish)..."
        sleep 2 || exec ${pkgs.fish}/bin/fish
      else
        echo ""
        echo "  shell crashed (exit $EXIT_CODE) — relaunching in 3s (Ctrl+C for fish)..."
        sleep 3 || exec ${pkgs.fish}/bin/fish
      fi
    done
  '';
in
{
  xdg.configFile."foot/foot.ini".text = ''
    shell=${raia-shell-launcher}
    term=xterm-256color
    title=raia
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

    [text-bindings]
    \x03=Control+Shift+c

    [colors-dark]
    background=000000
    alpha=0.95
  '';

  # Auto-launch foot on session start
  systemd.user.services.foot-appliance = {
    Unit = {
      Description = "Raia appliance terminal";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Install.WantedBy = [ "hyprland-session.target" ];

    Service = {
      ExecStart = "${pkgs.foot}/bin/foot";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=%t"
      ];
    };
  };
}
