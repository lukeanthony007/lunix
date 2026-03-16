# Raia Continuity Appliance

A minimal NixOS profile that boots directly into a guarded raia-shell experience.

## Boot path

```
hardware → bootloader → systemd → raia-core.service
                                → greetd → Hyprland → Foot → raia-shell
```

VM variant uses GRUB. Bare-metal uses systemd-boot (EFI).

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

Built entirely from source via a multi-stage Nix build:

1. **Stage 1 — Rust NAPI module**: Assembles the full Cargo workspace (raia + nayru, aether, anima, materia, mana, mythra) and builds `raia-kernel-node` as a cdylib `.node` file via `rustPlatform.buildRustPackage`.
2. **Stage 2 — npm dependencies**: Fixed-output derivation runs `bun install --frozen-lockfile` with network access, pinned by content hash. Preserves bun's symlink-based module resolution.
3. **Stage 3 — Bun compile**: Combines TypeScript source + NAPI module + node_modules. Runs `bun build --compile` to produce a self-contained ~154MB binary embedding Bun runtime, all JS/TS source, and the NAPI module.

The compiled binary only depends on glibc at runtime. No manual host-side build step is required.

Source: `packages/raia-core.nix`
Build: handled automatically by `just appliance-build` (requires `--impure` for local source paths)

### raia-core-stub

Minimal socat-based HTTP stub for boot-path validation without the real runtime. Used by the `appliance` NixOS config (for CI/eval). Not used by `appliance-real`.

Source: `packages/raia-core-stub.nix`

## Build and run

### Real appliance (recommended)

Builds raia-shell and raia-core from source, then builds the VM with real runtime. Everything is built by Nix — no manual host-side build steps:

```bash
just appliance-run          # build + run (fresh disk)
just appliance-run-persist  # build + run (keep disk state)
just appliance-build        # build VM only (runs --impure for local source paths)
```

### Stub appliance (for eval/CI)

Uses stub core — no real runtime, validates boot path only:

```bash
just appliance-build-stub   # no --impure needed
just appliance-check        # eval check only
```

### Bare-metal appliance

For deploying to real hardware (mini PC, laptop, etc.):

```bash
just appliance-bare-build    # build system closure (requires --impure)
```

Install on target hardware:

1. Boot the NixOS installer on the target machine
2. Partition the disk (EFI + root, label root as `nixos`, EFI as `BOOT`)
3. Run `nixos-generate-config --root /mnt`
4. Replace `hosts/appliance-bare/hardware-configuration.nix` with the generated version
5. Run `nixos-install --flake .#appliance-bare`

The bare-metal config uses systemd-boot (EFI), enables NetworkManager for WiFi, and includes redistributable firmware. The appliance experience (raia-core + greetd + Hyprland + Foot + raia-shell) is identical to the VM variant.

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

- Shell tracks core connectivity state and reflects it in the prompt (`[disconnected]`)
- On stream interruption mid-response, partial text is preserved with `[stream interrupted]` marker
- If streaming fails before any text arrives, shell falls back to synchronous `/api/cycle/run` automatically
- When disconnected, shell blocks natural-language input with a clear message (no silent failures)
- On next input attempt while disconnected, shell tries a quick health check and reconnects automatically
- `/reconnect` — retry core connectivity (3 attempts, 2s intervals) and verify session validity
- `/status` — shows core connection state and updates the `connected` flag
- Session continuity: sessions are server-side; after core restart, the existing session ID remains valid

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
- `raia-core` service (built from source — Rust NAPI + Bun compile)
- `raia-shell` binary (built from source — Rust)
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

Full three-step touch model: propose → confirm → execute.

- **Propose**: Runtime proposes a touch during a cycle. Touch appears as an escalation prompt in the shell.
- **Confirm**: `/confirm` queues the touch for execution (Proposed → Queued).
- **Execute**: `/execute` dispatches the touch through the runtime path (Queued → InFlight → Settled/Failed). The server handler performs dispatch, executes the effect, and settles in a single request.

Supported touch kinds for server-side execution:
- `fs-write`, `fs-delete`, `fs-move`, `fs-mkdir` — filesystem operations
- `memory-remember` — vault node creation
- `gm-*` — general memory operations (get/write/create via vault)

Shell commands: `/confirm`, `/reject`, `/execute`, `/touch`, `/touches`.

## Files

```
hosts/appliance/default.nix                # VM host profile (boot, services, QEMU config)
hosts/appliance-bare/default.nix           # Bare-metal host profile (EFI, NetworkManager)
hosts/appliance-bare/hardware-configuration.nix  # Hardware config (replace on target)
modules/services/raia.nix                  # raia-core systemd service + provisioning
home/luke/appliance.nix                    # Home Manager entry (imports below)
home/luke/appliance/hyprland.nix           # Simplified Hyprland for appliance
home/luke/appliance/foot.nix               # Foot → raia-shell launcher (with relaunch loop)
home/luke/appliance/provision.nix          # First-boot provisioning check service
packages/raia-shell.nix                    # Nix build for raia-shell (from source)
packages/raia-shell/Cargo.toml             # Standalone Cargo.toml for Nix build
packages/raia-shell/Cargo.lock             # Lock file for reproducible builds
packages/raia-core.nix                     # Multi-stage from-source build (Rust NAPI + npm + Bun compile)
packages/raia-core-stub.nix               # Stub server for boot-path testing (CI/eval)
```
