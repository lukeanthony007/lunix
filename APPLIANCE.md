# Raia Continuity Appliance

A minimal NixOS profile that boots directly into a guarded raia-shell experience.

## Boot path

```
hardware → GRUB → systemd → raia-core.service
                           → greetd → Hyprland → Foot → raia-shell
```

- `raia-core` starts as a system service on boot
- greetd auto-logs in and starts Hyprland
- Hyprland launches Foot via a user service
- Foot's shell is a launcher script that waits for core readiness, then starts `raia-shell`
- If shell exits or crashes, launcher loops and relaunches automatically

## Packaging

### raia-shell

Built from source via `rustPlatform.buildRustPackage`. Uses a standalone `Cargo.toml` decoupled from the raia workspace (raia-shell has no workspace-internal path deps — all dependencies are from crates.io).

Source: `packages/raia-shell.nix`
Standalone Cargo files: `packages/raia-shell/Cargo.toml`, `packages/raia-shell/Cargo.lock`

### raia-core

Wrapped pre-built binary. Built outside Nix via `bun build --compile`, which produces a self-contained executable embedding:
- Bun runtime
- All TypeScript source (core.ts + raia-cognition stack)
- NAPI native module (raia-kernel-node, ~216MB .node module)

The compiled binary only depends on glibc at runtime.

Source: `packages/raia-core.nix`
Build command: `just raia-core-build` (runs `bun build --compile` in raia repo)

### raia-core-stub

Minimal socat-based HTTP stub for boot-path validation without the real runtime. Used by the `appliance` NixOS config (for CI/eval). Not used by `appliance-real`.

Source: `packages/raia-core-stub.nix`

## Build and run

### Real appliance (recommended)

Builds both raia-shell and raia-core from source, then builds the VM with real runtime:

```bash
just appliance-run          # build + run (fresh disk)
just appliance-run-persist  # build + run (keep disk state)
```

Individual build steps:

```bash
just raia-shell-build   # cargo build raia-shell
just raia-core-build    # bun compile raia-core
just raia-build         # both
just appliance-build    # build VM (requires raia-build first, runs --impure)
```

### Stub appliance (for eval/CI)

Uses stub core — no real runtime, validates boot path only:

```bash
just appliance-build-stub   # no --impure needed
just appliance-check        # eval check only
```

### Persist disk state

To keep provisioning state between VM restarts:

```bash
just appliance-run-persist
```

## First-boot provisioning

On first boot, the appliance is not yet provisioned. The shell launcher detects this and drops into a diagnostic Fish prompt with instructions.

Run provisioning:

```
raia-provision
```

This prompts for:
- **Anthropic API key** — stored at `~/.raia/secrets/anthropic.key` (mode 0600)

It also creates:
- `~/.raia/domain.toml` — appliance domain manifest
- `~/.raia/deployment.json` — deployment context (appliance/production/established)
- `~/.raia/.provisioned` — marker file

After provisioning, restart core:

```
sudo systemctl restart raia-core
```

Then open a new Foot terminal or restart the session.

## Deployment context

The appliance boots with a conservative default context:

| Field | Value |
|-------|-------|
| Embodiment | `appliance` |
| Environment | `production` |
| Trust tier | `established` |
| Label | `raia-appliance` |

This context is set in `~/.raia/deployment.json` and passed to raia-core via environment variables. Gated actions respect this context through the trust model.

Inspect the active context via raia-shell:

```
/diag
/status
/reconnect
```

## Restart and failure behavior

### Core restart

- Service: `Restart=on-failure`, 5 retries in 120s, 5s between retries
- Readiness: ExecStartPost polls `/health/ready` for up to 60s
- TimeoutStartSec: 90s (real core loads ~216MB NAPI module)
- Journal: `journalctl -u raia-core -f`

### Shell behavior after core restart

- Shell detects core unavailability on next input attempt
- Prints diagnostic: "core is unreachable — check that the server is running on :4111"
- Shell stays open — user can retry when core comes back
- `/reconnect` — explicitly re-check core and session state
- `/status` — shows core connection state

### Shell exit/crash

- Launcher automatically relaunches shell after brief pause (2-3s)
- Ctrl+C during pause drops to Fish for debugging
- Opening a new Foot terminal re-runs the launcher (re-checks readiness)

### Provisioning gate

- Core refuses to start without `~/.raia/.provisioned`
- Shell launcher detects this and drops to Fish with provisioning instructions
- After provisioning + core restart, launcher picks up automatically

## Inspecting failures

### raia-core won't start

```bash
systemctl status raia-core
journalctl -u raia-core -f
```

Common causes:
- Not provisioned (run `raia-provision`)
- Port 4111 in use
- Missing API key

### Shell won't connect

The Foot launcher waits up to 60s for core readiness. If it times out, it drops to a diagnostic Fish shell. Exiting Fish retries.

```bash
# Check core health manually
curl http://localhost:4111/health/ready
```

### Hyprland won't start

Falls back to a Fish shell on the TTY with a diagnostic message. Switch to TTY2 (Ctrl+Alt+F2) for a login prompt.

```bash
journalctl --user -u hyprland-session
```

### Unclean shutdown / reboot

The raia-core service is configured with `Restart=on-failure` (5 retries in 120s). The systemd journal preserves crash context across reboots.

### Network unavailable

raia-core and raia-shell function locally. If external API calls fail (e.g., Anthropic), the runtime reports errors through the shell's response annotations. The appliance remains interactive.

## What's included vs. stripped

### Included

- Hyprland (compositor)
- greetd (session launcher)
- PipeWire (audio)
- Fish (fallback shell)
- Foot (terminal)
- System fonts
- Networking (NetworkManager)
- SSH
- `raia-core` service (real packaged runtime)
- `raia-shell` binary (built from source)
- `raia-provision` tool

### Stripped (vs. desktop profile)

- Gaming (Steam, RetroArch, gamescope)
- Productivity (Discord, Obsidian, Signal, Zoom)
- Browser (Zen)
- Cloud sync (rclone)
- VSCode
- Home Assistant
- Jellyfin
- Docker
- DMS (desktop shell)
- Bootstrap welcome wizard
- General workstation packages

## Touch execution

Two-step touch model (propose → confirm/reject) is retained for Wave 3.5. The appliance does not require touch execution to prove continuity terminal viability. Shell commands: `/confirm`, `/reject`, `/touch`, `/touches`.

## Files

```
hosts/appliance/default.nix        # Host profile (boot, services, VM config)
modules/services/raia.nix           # raia-core systemd service + provisioning
home/luke/appliance.nix             # Home Manager entry (imports below)
home/luke/appliance/hyprland.nix    # Simplified Hyprland for appliance
home/luke/appliance/foot.nix        # Foot → raia-shell launcher (with relaunch loop)
home/luke/appliance/provision.nix   # First-boot provisioning check service
packages/raia-shell.nix             # Nix build for raia-shell (from source)
packages/raia-shell/Cargo.toml      # Standalone Cargo.toml for Nix build
packages/raia-shell/Cargo.lock      # Lock file for reproducible builds
packages/raia-core.nix              # Nix wrapper for pre-built raia-core binary
packages/raia-core-stub.nix         # Stub server for boot-path testing (CI/eval)
```
