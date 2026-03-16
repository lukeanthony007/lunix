{ config, lib, pkgs, applianceUser ? "luke", ... }:

let
  cfg = config.services.raia-core;

  # Readiness check script — polls /health/ready until 200 or timeout.
  # Logs state transitions for journal inspection.
  readinessCheck = pkgs.writeShellScript "raia-core-ready" ''
    URL="http://127.0.0.1:${toString cfg.port}/health/ready"
    TIMEOUT=''${1:-60}
    ELAPSED=0
    LAST_STATUS=""
    while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
      STATUS=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
      if [ "$STATUS" = "200" ]; then
        BODY=$(${pkgs.curl}/bin/curl -s "$URL" 2>/dev/null)
        echo "raia-core ready after ''${ELAPSED}s ($BODY)"
        exit 0
      fi
      if [ "$STATUS" != "$LAST_STATUS" ]; then
        echo "raia-core: waiting (status=$STATUS, elapsed=''${ELAPSED}s)" >&2
        LAST_STATUS="$STATUS"
      fi
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done
    echo "raia-core not ready after ''${TIMEOUT}s (last status: $STATUS)" >&2
    exit 1
  '';

  # First-boot provisioning script
  provisionScript = pkgs.writeShellScriptBin "raia-provision" ''
    export PATH="${lib.makeBinPath (with pkgs; [ coreutils ])}:$PATH"

    RAIA_HOME="''${HOME}/.raia"
    SECRETS_DIR="''${RAIA_HOME}/secrets"
    DOMAIN_DIR="''${RAIA_HOME}"

    echo ""
    echo "=== Raia Appliance Provisioning ==="
    echo ""

    # Ensure directories exist with correct permissions
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    mkdir -p "$DOMAIN_DIR"

    NEEDS_PROVISION=false

    # Check for Anthropic API key
    if [ ! -f "$SECRETS_DIR/anthropic.key" ] || [ ! -s "$SECRETS_DIR/anthropic.key" ]; then
      NEEDS_PROVISION=true
      echo "Anthropic API key is required for the continuity runtime."
      echo ""
      printf "Enter your Anthropic API key: "
      read -r API_KEY
      if [ -z "$API_KEY" ]; then
        echo "No key provided. Provisioning incomplete."
        echo "Run 'raia-provision' again when ready."
        exit 1
      fi
      echo -n "$API_KEY" > "$SECRETS_DIR/anthropic.key"
      chmod 600 "$SECRETS_DIR/anthropic.key"
      echo "API key saved."
    else
      echo "Anthropic API key: present"
    fi

    # Create minimal domain manifest if missing
    if [ ! -f "$DOMAIN_DIR/domain.toml" ]; then
      NEEDS_PROVISION=true
      cat > "$DOMAIN_DIR/domain.toml" << 'TOML'
[domain]
name = "appliance"
description = "Raia continuity appliance"

[surfaces.shell]
name = "shell"
kind = "text"
primary = true

[deployment]
embodiment = "appliance"
environment = "production"
trust_tier = "established"
label = "raia-appliance"
TOML
      echo "Domain manifest created."
    else
      echo "Domain manifest: present"
    fi

    # Create deployment context file
    if [ ! -f "$DOMAIN_DIR/deployment.json" ]; then
      cat > "$DOMAIN_DIR/deployment.json" << 'JSON'
{
  "embodiment": "appliance",
  "environment": "production",
  "trust_tier": "established",
  "label": "raia-appliance"
}
JSON
      echo "Deployment context: appliance/production/established"
    else
      echo "Deployment context: present"
    fi

    # Mark provisioning complete
    touch "$RAIA_HOME/.provisioned"
    echo ""
    echo "Provisioning complete."
    echo "Restart raia-core to apply: sudo systemctl restart raia-core"
    echo ""
  '';

  # Wrapper script that starts raia-core
  coreStartScript = pkgs.writeShellScript "raia-core-start" ''
    export PATH="${lib.makeBinPath (with pkgs; [ coreutils ])}:$PATH"
    export HOME="${cfg.home}"
    export RAIA_COGNITION_PORT="${toString cfg.port}"
    export RAIA_HOME="${cfg.home}/.raia"

    # Check provisioning state
    if [ ! -f "$RAIA_HOME/.provisioned" ]; then
      echo "raia-core: not provisioned — run 'raia-provision' first" >&2
      exit 1
    fi

    # Load secrets from file into environment
    if [ -f "$RAIA_HOME/secrets/anthropic.key" ]; then
      export ANTHROPIC_API_KEY="$(cat "$RAIA_HOME/secrets/anthropic.key")"
    fi

    if [ -f "$RAIA_HOME/secrets/openai.key" ]; then
      export OPENAI_API_KEY="$(cat "$RAIA_HOME/secrets/openai.key")"
    fi

    # Set deployment context environment
    export RAIA_EMBODIMENT="appliance"
    export RAIA_ENVIRONMENT="production"
    export RAIA_TRUST_TIER="established"

    echo "raia-core: starting (port=$RAIA_COGNITION_PORT, home=$RAIA_HOME)"

    # Start the core server
    exec ${cfg.coreCommand}
  '';
in
{
  options.services.raia-core = {
    enable = lib.mkEnableOption "Raia continuity runtime core";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4111;
      description = "HTTP API port for raia-core";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/${applianceUser}";
      description = "Home directory of the user running raia-core";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = applianceUser;
      description = "User to run raia-core as";
    };

    coreCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to start the raia-core server process";
    };

    shellPackage = lib.mkOption {
      type = lib.types.package;
      description = "The raia-shell binary package";
    };
  };

  config = lib.mkIf cfg.enable {
    # System-level systemd service for raia-core
    systemd.services.raia-core = {
      description = "Raia Continuity Runtime";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = coreStartScript;
        ExecStartPost = "${readinessCheck} 60";
        TimeoutStartSec = 90;
        Restart = "on-failure";
        RestartSec = 5;
        StartLimitBurst = 5;
        StartLimitIntervalSec = 120;

        # Hardening
        ProtectSystem = "strict";
        ReadWritePaths = [ "${cfg.home}/.raia" ];
        PrivateTmp = true;
        NoNewPrivileges = true;

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "raia-core";
      };
    };

    # Make raia-shell and provisioning tool available system-wide
    environment.systemPackages = [
      cfg.shellPackage
      provisionScript
    ];
  };
}
