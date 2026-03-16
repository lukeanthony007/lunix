# lu-nix System Guide

Canonical architecture and operations reference for this NixOS + standalone Home Manager flake — how it's structured, what every file does, and how to operate it.

---

## Current Status

| Target | State |
|--------|-------|
| Arch + standalone Home Manager | **Primary path** — daily driver |
| NixOS `desktop` | Available, not actively used |
| NixOS `vm-dev` | Validated — used for testing |
| NixOS `laptop` | Placeholder — hardware config not populated |
| DMS on Arch | Running — requires GL fixups in `arch-gl.nix` |

**Current compositor:** Hyprland is the only compositor target. All Hyprland config is active and current. There is no Niri, Sway, or other compositor config in this repo.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Ownership Model](#ownership-model)
3. [Flake Entry Point](#flake-entry-point)
4. [Deployment Targets](#deployment-targets)
5. [Directory Structure](#directory-structure)
6. [Portability Map](#portability-map)
7. [System-Level Modules (`modules/`)](#system-level-modules)
8. [Host Configurations (`hosts/`)](#host-configurations)
9. [Home Manager (`home/luke/`)](#home-manager)
10. [Desktop Environment Stack](#desktop-environment-stack)
11. [Application Configuration](#application-configuration)
12. [Custom Services & Automation](#custom-services--automation)
13. [Development Tooling](#development-tooling)
14. [Keybindings Reference](#keybindings-reference)
15. [Build & Deploy Commands](#build--deploy-commands)
16. [Known Coupling Points](#known-coupling-points)
17. [Migration Guide](#migration-guide)
18. [Recovery Guide](#recovery-guide)
19. [Bring-Up Checklist](#bring-up-checklist)

---

## Architecture Overview

This flake manages a complete Linux desktop across three operating modes:

| Mode | Role | What it manages |
|------|------|-----------------|
| **Arch + HM** | Primary daily driver | User environment only — shell, apps, desktop, services |
| **NixOS desktop** | Full-system alternative | Entire system — kernel, services, users, plus Home Manager |
| **NixOS vm-dev** | Validation target | Testing changes in a disposable VM before applying elsewhere |

The desktop stack is **Hyprland** (Wayland compositor) + **Dank Material Shell (DMS)** (shell/panel/theming) + **Foot** (terminal) + **Fish** (shell). Everything is declarative and reproducible.

```
flake.nix
├── homeConfigurations.luke      ← Standalone HM on Arch (primary)
├── nixosConfigurations.desktop  ← Full NixOS desktop
└── nixosConfigurations.vm-dev   ← Development VM
```

---

## Ownership Model

On Arch (the primary deployment), responsibilities are split between the host OS and Home Manager:

### Arch owns

- Kernel, boot, drivers (GPU, WiFi, Bluetooth)
- System services: greetd/SDDM, NetworkManager, PipeWire, SSH, Docker
- Compositor binary (Hyprland installed via pacman)
- XDG portals and polkit
- GL/EGL driver stack (`/usr/lib/dri`, `/usr/share/glvnd`)

### Home Manager owns

- Shell environment (Fish, starship, zoxide, fzf)
- Editors (VSCode, Neovim)
- User applications (Zen, Spotify, Discord, Obsidian, etc.)
- Desktop theming (GTK, Qt, DMS, cursor)
- Hyprland configuration (keybinds, rules, animations, monitor)
- DMS user-level service and config (clipboard, wallpaper, dsearch)
- User systemd services (bootstrap, cloud-sync, foot-autostart)
- All `~/.config` managed files

> On Arch, DMS is Nix-built and HM-managed at the user level, but depends on Arch's system GL/EGL stack to render. The `arch-gl.nix` shim bridges this by injecting Arch driver paths into the DMS service environment.

### Dev shell owns

- Rust toolchain (via oxalica overlay)
- Node.js / pnpm
- clang / lld
- Build dependencies (openssl, sqlite, pkg-config)
- Language servers

### On NixOS (desktop/vm-dev), NixOS additionally owns

- Everything Arch owns above, declared in `modules/` and `hosts/`
- System-level DMS (greeter config)
- System fonts
- User account definition

---

## Flake Entry Point

**File:** `flake.nix`

### Inputs

| Input | Purpose |
|-------|---------|
| `nixpkgs` | nixos-unstable channel |
| `home-manager` | User environment management |
| `rust-overlay` | Pinned Rust toolchain with extensions |
| `dms` | Dank Material Shell compositor shell |
| `dms-plugin-registry` | DMS plugin ecosystem |
| `danksearch` | App launcher for DMS |
| `zen-browser` | Firefox fork (Zen) |
| `spicetify-nix` | Spotify customization |

### Key helpers defined in the flake

- **`mkPkgs`** — Creates a nixpkgs instance with `allowUnfree` and the rust-overlay applied.
- **`mkRustToolchain`** — Stable Rust with clippy, rust-analyzer, rustfmt, llvm-tools-preview, rust-src, and `wasm32-unknown-unknown` target.
- **`mkNodejs`** — Resolves `nodejs_24` with a fallback to `nodejs`.
- **`mkHost`** — Factory for NixOS configurations. Injects DMS NixOS modules, Home Manager integration, and passes `inputs`, `rustToolchain`, `nodejs`, and `self` as special args.

### Dev shell

The flake provides a `devShells.default` for all systems with: Rust toolchain, Node.js, pnpm, biome, cargo tools (deny, edit, nextest), bacon, ripgrep, fd, jq, just, SQLite, clang/lld, and language servers (typescript-language-server, vscode-langservers-extracted).

---

## Deployment Targets

### `homeConfigurations.luke` (Arch Linux — primary)

The standalone Home Manager configuration for use on Arch. Imports:

- `home/luke/` — base (shell, git, editors)
- `home/luke/desktop.nix` — full desktop environment
- `home/luke/desktop/arch-gl.nix` — GL driver fixups for Nix apps on Arch
- `home/luke/gaming.nix` — emulators and gaming tools
- `home/luke/productivity.nix` — communication and productivity apps

Shared Home Manager modules (DMS, DMS plugins, danksearch, spicetify, zen-browser) are injected into all configurations.

### `nixosConfigurations.desktop`

Full NixOS for the desktop machine. Same Home Manager modules as Arch plus NixOS system modules (core, graphical, development).

### `nixosConfigurations.vm-dev`

QEMU development VM for testing. Uses GRUB, virtio-gpu, 4 cores / 8 GB RAM. Includes a Hyprland session with VM-specific overrides (CTRL as mod key, auto-detect monitor). The VM runner depends on host QEMU for virgl/GTK rendering on non-NixOS hosts.

---

## Directory Structure

```
lu-nix/
├── flake.nix                           # Flake definition & outputs
├── flake.lock                          # Pinned input versions
├── justfile                            # VM build/run recipes
│
├── modules/                            # NixOS system modules
│   ├── default.nix                     # Imports core, graphical, development
│   ├── core/
│   │   ├── default.nix                 # Imports base, ssh, users
│   │   ├── base.nix                    # Nix settings, locale, system packages
│   │   ├── ssh.nix                     # OpenSSH hardening
│   │   └── users.nix                   # User account (luke)
│   ├── graphical/
│   │   ├── default.nix                 # Imports audio, dms, fonts
│   │   ├── audio.nix                   # PipeWire audio stack
│   │   ├── dms.nix                     # System-level DMS + greeter
│   │   └── fonts.nix                   # System fonts
│   └── development/
│       ├── default.nix                 # Imports rust, typescript
│       ├── rust.nix                    # Rust toolchain + native deps
│       └── typescript.nix              # Node.js + pnpm
│
├── hosts/                              # Machine-specific NixOS configs
│   ├── desktop/
│   │   ├── default.nix                 # Desktop host: AMD GPU, WiFi, Steam, Jellyfin, Home Assistant
│   │   └── hardware-configuration.nix  # Disk layout, CPU, boot modules
│   ├── laptop/
│   │   ├── default.nix                 # Laptop host (minimal placeholder)
│   │   └── hardware-configuration.nix  # Placeholder
│   └── vm-dev/
│       └── default.nix                 # Dev VM: GRUB, QEMU guest, greetd
│
└── home/luke/                          # Home Manager configuration
    ├── default.nix                     # Base: imports shell, git, editors
    ├── shell.nix                       # Fish, starship, zoxide, fzf, aliases
    ├── git.nix                         # Git identity & credential helpers
    ├── editors.nix                     # Neovim setup
    ├── desktop.nix                     # Desktop entry point: packages, MIME, GTK, services
    ├── bootstrap.nix                   # First-login welcome screen (QuickShell)
    ├── cloud-sync.nix                  # rclone cloud sync module
    ├── gaming.nix                      # Emulators (RetroArch, Dolphin, PCSX2)
    ├── productivity.nix                # Discord, Obsidian, Signal, Zoom, Deluge
    └── desktop/
        ├── arch-gl.nix                 # Arch GL driver fixups for Nix binaries
        ├── dms.nix                     # DMS user-level service and config
        ├── foot.nix                    # Foot terminal configuration
        ├── hyprland.nix                # Hyprland WM: keybinds, rules, animations
        ├── hyprland-vm.nix             # VM-specific Hyprland overrides
        ├── qt.nix                      # Qt6 theme (Darkly + DankMatugen colors)
        ├── settings.nix                # QuickShell settings app
        ├── spicetify.nix               # Spotify customization
        ├── vscode.nix                  # VSCode: extensions, settings, theme
        └── zen.nix                     # Zen Browser + extensions
```

---

## Portability Map

Every config file falls into one of three categories. This matters when bringing up a new machine.

### Portable (works on any host)

| File | What it configures |
|------|--------------------|
| `home/luke/default.nix` | Base HM (shell, git, editors) |
| `home/luke/shell.nix` | Fish, starship, zoxide, fzf, aliases |
| `home/luke/git.nix` | Git identity & credential helpers |
| `home/luke/editors.nix` | Neovim |
| `home/luke/productivity.nix` | Discord, Obsidian, Signal, Zoom, Deluge |
| `home/luke/gaming.nix` | RetroArch, Dolphin, PCSX2, gamescope |
| `home/luke/cloud-sync.nix` | rclone sync module |
| `home/luke/desktop/dms.nix` | DMS user-level service and config |
| `home/luke/desktop/foot.nix` | Foot terminal |
| `home/luke/desktop/qt.nix` | Qt6 theming |
| `home/luke/desktop/spicetify.nix` | Spotify customization |
| `home/luke/desktop/vscode.nix` | VSCode extensions & settings |
| `home/luke/desktop/zen.nix` | Zen Browser extensions |
| `home/luke/desktop/settings.nix` | QuickShell settings app |
| `home/luke/bootstrap.nix` | First-login welcome screen |

### Host-specific (tied to hardware or machine)

| File | Why it's host-specific |
|------|------------------------|
| `home/luke/desktop/hyprland.nix` | Monitor definition (`DP-1, 2560x1440@164Hz`), mouse button binds |
| `home/luke/desktop.nix` | `qemu` package only needed on desktop |
| `hosts/desktop/default.nix` | AMD GPU, Intel AX210, storage mounts, Jellyfin, Home Assistant |
| `hosts/desktop/hardware-configuration.nix` | Disk UUIDs, boot modules, CPU platform |

### Arch-only

| File | Why it's Arch-only |
|------|---------------------|
| `home/luke/desktop/arch-gl.nix` | GL driver path fixups for Nix-on-Arch |

### VM-only

| File | Why it's VM-only |
|------|-------------------|
| `home/luke/desktop/hyprland-vm.nix` | CTRL mod key, auto-detect monitor |
| `hosts/vm-dev/default.nix` | GRUB, QEMU guest, greetd session script, VM resources |

---

## System-Level Modules

These are NixOS modules used by `nixosConfigurations.*` hosts. They are **not** used by the standalone Home Manager configuration on Arch.

### `modules/core/base.nix`

Foundation for all NixOS hosts:

- **Nix settings:** Enables flakes and `nix-command` experimental features.
- **Garbage collection:** Weekly, deletes generations older than 7 days. Store optimisation enabled.
- **Networking:** NetworkManager.
- **Locale:** `en_US.UTF-8`, US keymap.
- **Services:** dbus, polkit, XDG portal (GTK backend, `xdgOpenUsePortal` on).
- **Docker:** Enabled.
- **System packages:** curl, fd, jq, just, ripgrep, tree, vim, wget.
- **State version:** `25.11`.

### `modules/core/ssh.nix`

Hardened OpenSSH server:

- Password authentication disabled.
- Keyboard-interactive authentication disabled.
- Root login prohibited.
- Firewall opened for SSH.

### `modules/core/users.nix`

User account definition:

- **User:** `luke` (normal user).
- **Groups:** audio, docker, networkmanager, video, wheel.
- **Shell:** Fish.
- **Initial password:** `luke` (mutable users enabled).

### `modules/graphical/audio.nix`

PipeWire audio stack replacing PulseAudio:

- ALSA (32-bit support), JACK emulation, PulseAudio emulation.
- WirePlumber session manager.
- pavucontrol GUI.

### `modules/graphical/dms.nix`

System-level Dank Material Shell configuration:

- DMS enabled with systemd integration and auto-restart.
- Features: system monitoring, VPN, dynamic theming, audio wavelength visualisation, calendar events, clipboard paste.
- **Greeter:** DMS greeter using Hyprland as compositor, config home at `/home/luke`.

### `modules/graphical/fonts.nix`

System fonts: Inter, Liberation, Material Symbols, Noto (+ color emoji), Source Code Pro.

### `modules/development/rust.nix`

Rust development environment:

- Rust toolchain (from overlay), clang, lld, pkg-config, OpenSSL, SQLite.
- Environment variables: `LIBCLANG_PATH`, `RUST_SRC_PATH`.

### `modules/development/typescript.nix`

TypeScript/Node.js: Node.js (v24 when available) and pnpm.

---

## Host Configurations

### `hosts/desktop/`

The primary desktop machine (NixOS):

- **Boot:** systemd-boot, EFI at `/boot/efi`.
- **GPU:** AMD RX 5700 XT (RDNA 1) via `amdgpu`.
- **Networking:** Intel AX210 (WiFi + Bluetooth enabled, power-on-boot).
- **Firmware:** Redistributable firmware enabled.
- **Gaming:** Steam and gamemode enabled at system level.
- **Media:** Jellyfin media server (firewall opened).
- **Home automation:** Home Assistant with `default_config` and `met` components.

**Hardware (`hardware-configuration.nix`):**

| Mount | Device | Filesystem |
|-------|--------|------------|
| `/` | ext4 partition | ext4 |
| `/boot/efi` | EFI partition | vfat |
| `/mnt/Media` | media partition | exfat |
| `/mnt/Games` | games partition | ext4 |

Intel KVM platform, boot modules: xhci_pci, ahci, nvme, usbhid, sd_mod.

### `hosts/laptop/`

Minimal laptop configuration — just imports core and graphical modules. Hardware config is a placeholder.

### `hosts/vm-dev/`

QEMU development VM:

- **Boot:** GRUB (no EFI).
- **Filesystem:** ext4 root on `/dev/disk/by-label/nixos`.
- **Session:** greetd launches a custom Hyprland session script that creates DMS stub configs and starts Hyprland.
- **QEMU guest agent** enabled.
- **VM resources:** 4 cores, 8 GB RAM, 8 GB disk, virtio-gpu (GTK display), PipeWire audio passthrough.

---

## Home Manager

### `home/luke/default.nix`

The base Home Manager entry point, always imported regardless of deployment target:

- **Username:** `luke`, home at `/home/luke`.
- **Imports:** `shell.nix`, `git.nix`, `editors.nix`.
- **State version:** `25.11`.

### `home/luke/shell.nix`

Shell environment built on Fish:

**Packages:** bat, eza, fd, fzf, ripgrep, uv.

**Session variables:**

| Variable | Value |
|----------|-------|
| `EDITOR` | `nvim` |
| `TERMINAL` | `foot` |
| `ELECTRON_OZONE_PLATFORM_HINT` | `auto` |
| `OZONE_PLATFORM` | `wayland` |
| `NATIVE_WAYLAND` | `1` |

**Session PATH:** `~/.bun/bin`

**Fish configuration:**

- Greeting suppressed.
- 5 plugins: fzf-fish, autopair, done (notifications), sponge (history cleanup), puffer (abbreviation expansion).

**Shell abbreviations:**

| Abbr | Expands to |
|------|------------|
| `gs` | `git status` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git log --oneline` |
| `gco` | `git checkout` |
| `ls` | `eza` |
| `ll` | `eza -la` |
| `lt` | `eza --tree --level=2` |
| `cat` | `bat` |
| `hms` | `home-manager switch --flake .` |

> **Note:** The `hms` abbreviation uses `--flake .` which relies on Home Manager inferring the config name from `$USER`. The fully explicit form is `home-manager switch --flake .#luke`.

**Tools:**

- **fzf** — fuzzy finder (Fish integration via fzf-fish plugin, not the built-in).
- **zoxide** — smart `cd` with directory history.
- **starship** — cross-shell prompt (config at `config/starship.toml`).

### `home/luke/git.nix`

- **Name:** Luke Anthony
- **Email:** ln64.ohio@gmail.com
- **Default branch:** main
- **Credential helper:** `gh auth git-credential` for github.com and gist.github.com.
- **Global ignores:** `**/.claude/settings.local.json`

### `home/luke/editors.nix`

Neovim as default editor:

- `vi` and `vim` aliased to `nvim`.
- **Plugin:** transparent.nvim — forces transparent backgrounds and fixes StatusLine highlight groups.

### `home/luke/productivity.nix`

Productivity packages: Deluge (torrents), Discord, Obsidian, Signal Desktop, Zoom.

### `home/luke/gaming.nix`

Gaming and emulation:

**Standalone emulators:**

| Emulator | Systems |
|----------|---------|
| Dolphin | GameCube, Wii |
| PCSX2 | PlayStation 2 |

**RetroArch cores:**

| Core | System |
|------|--------|
| beetle-psx-hw | PlayStation 1 |
| fceumm | NES |
| flycast | Dreamcast |
| mgba | Game Boy Advance |
| mupen64plus | Nintendo 64 |
| ppsspp | PSP |
| snes9x | SNES |

**Tools:** gamescope (micro-compositor for games), mangohud (FPS overlay), protonup-qt (Proton GE manager).

**RetroArch config:** XMB menu driver, theme 20, 95% alpha factor. Only written if no existing config exists.

---

## Desktop Environment Stack

### `home/luke/desktop.nix`

The desktop entry point — imported for graphical setups. Pulls in all desktop sub-modules and defines:

**Packages:** btop, bun, claude-code, codex, fastfetch, foot, imv, gnome-text-editor, mpv, Thunar, adw-gtk3, JetBrains Mono Nerd Font, p7zip, pavucontrol, qemu, unzip.

**XDG user directories:** Enabled with auto-creation (Desktop, Documents, Downloads, etc.).

**Default applications (MIME):**

| Type | Application |
|------|-------------|
| HTTP/HTTPS, HTML, XHTML | Zen Browser |
| MP4, QuickTime | mpv |
| PNG, JPEG | GNOME Loupe |
| TOML, shell scripts | VSCode |
| Directories | Thunar |
| Discord protocol | Vesktop |

**GTK theme:** adw-gtk3-dark. Cursor: Adwaita (24px). Dark color scheme via dconf.

**Services enabled:** bootstrap (first-login), cloud-sync (Backblaze B2 for Documents + Pictures).

### `home/luke/desktop/hyprland.nix`

The core window manager configuration.

**Custom scripts (defined in `let` block):**

| Script | Purpose |
|--------|---------|
| `hypr-kill` | Kills active window; uses `pkill` for apps that ignore WM close (e.g., Spotify) |
| `focus-window` | Focuses existing window by class, or launches app if not running. `-n` flag forces new instance |
| `hypr-zoom` | Zoom in/out using `cursor:zoom_factor`. `hypr-zoom in [step]` / `hypr-zoom out` |

**Activation script:** Creates DMS stub config files (`execs`, `general`, `keybinds`, `rules`, `cursor`) in `~/.config/hypr/dms/` so Hyprland can parse `source=` lines before DMS generates them.

**Monitor:** `DP-1` at 2560x1440@164.06Hz, scale 2, VRR enabled. Fallback: preferred/auto. *(Host-specific — will need override on other machines.)*

**Environment:**

| Variable | Value |
|----------|-------|
| `GTK_THEME` | `Adwaita-dark` |
| `QT_QPA_PLATFORMTHEME` | `qt6ct` |
| `NIXOS_OZONE_WL` | `1` |

**General layout:**

- Dwindle layout with `preserve_split`.
- Gaps: 10px inner, 15px outer.
- Border size: 0 (borderless).
- Rounding: 12px.

**Decoration:**

- Blur: enabled, size 2, 1 pass, vibrancy 0.2.
- Shadows: enabled, range 40, render power 4, offset 0/5, color rgba(00000070).

**Animations:**

- Workspace transitions: vertical slide.
- Special workspace: vertical slide from top.

**Cursor:** Hidden on keypress, no warps.

**Misc:** VRR on, no Hyprland logo/splash, ANR dialog disabled.

**DMS integration:** Sources 5 config files from `~/.config/hypr/dms/` (execs, general, keybinds, rules, cursor). DMS spotlight toggled with Super key tap.

### `home/luke/desktop/hyprland-vm.nix`

VM overrides applied on top of the main Hyprland config:

- Mod key changed from `SUPER` to `CTRL` (avoids conflict with host).
- Monitor set to auto-detect (`preferred,auto,1`).
- Foot launched via direct Nix store path.

### `home/luke/desktop/dms.nix`

Dank Material Shell user-level service and runtime configuration:

- Settings loaded from `config/dms-settings.json`.
- **Clipboard:** 25 items max, 5 MB per entry, auto-clear daily, clear at startup, persist disabled.
- **dsearch** (app search) enabled.
- **Random wallpaper service:** Runs before DMS starts, picks a random image from `~/Pictures/Wallpapers` and writes it into DMS `session.json`. Currently disabled (bootstrap handles wallpaper selection instead).

### `home/luke/desktop/foot.nix`

Foot terminal emulator:

- **Shell:** Fish
- **Font:** JetBrainsMono Nerd Font, 20pt
- **Padding:** 40x40
- **Scrollback:** 10,000 lines
- **Cursor:** Beam, blink enabled, 1.5px thickness
- **Background:** `#000000` at 85% opacity
- **Colors:** Sourced from DMS-generated `dank-colors.ini`

**Key bindings:**

| Key | Action |
|-----|--------|
| Ctrl+C | Copy (Ctrl+Shift+C sends SIGINT) |
| Ctrl+V | Paste |
| Ctrl+F | Search |
| Ctrl+Plus/Minus/0 | Font size |
| Page Up/Down | Scroll |

**Services:**

- `foot-fix-colors` — Path-triggered service that renames deprecated `[colors]` section to `[colors-dark]` in the DMS color config whenever it changes.
- `foot-autostart` — Launches foot after Hyprland + DMS are ready. Waits up to 15 seconds for `dank-colors.ini` to appear, applies the color fix, then starts foot.

### `home/luke/desktop/qt.nix`

Qt6 theming via qt6ct:

- **Style:** Darkly
- **Icons:** OneUI
- **Color scheme:** DankMatugen (from DMS dynamic theming)
- **Fonts:** Rubik (UI), JetBrainsMono Nerd Font (monospace)
- **Platform theme:** qtct

### `home/luke/desktop/arch-gl.nix`

Fixes for running Nix-built graphical apps (DMS, QuickShell) on Arch Linux, where Nix's bundled Mesa lacks DRI drivers:

**DMS service overrides:**

| Setting | Purpose |
|---------|---------|
| `LIBGL_DRIVERS_PATH=/usr/lib/dri` | Use Arch's GL drivers |
| `__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d` | Use Arch's EGL vendor files |
| `LD_LIBRARY_PATH=/usr/lib` | Link against Arch system libraries |

- DMS bound to `hyprland-session.target` (not `graphical-session.target`) to ensure the Wayland socket exists.
- Generous restart limits: 10 restarts within 60 seconds to survive logout/login gaps.
- Same GL environment applied to the bootstrap service.

---

## Application Configuration

### `home/luke/desktop/vscode.nix`

VSCode with fully managed extensions (immutable extensions directory):

**Extensions:**

| Extension | Source |
|-----------|--------|
| Claude Code | nixpkgs |
| Nix IDE | nixpkgs |
| Just | nixpkgs |
| ErrorLens | nixpkgs |
| Base16 Themes | Marketplace |
| Bearded Theme OLED | Marketplace |
| ChatGPT (OpenAI) | Marketplace |

**Editor settings:**

- Auto-save after delay, format on save.
- No line numbers, no tabs, no breadcrumbs, no minimap, no activity bar, no status bar, no menu bar.
- Sidebar on right side.
- Font: FiraCode Nerd Font (weight 600, ligatures, line height 24).
- Terminal font: SpaceMono Nerd Font.
- Tab size: 2.
- Zoom level: +3, mouse wheel zoom enabled.
- Inlay hints: off unless Ctrl held.

**Theme:** Bearded Theme OLED (Experimental) with extensive pure black (`#000000`) color overrides for editor, sidebar, activity bar, status bar, title bar, tabs, panel, terminal, and widgets.

**Language support:**

- Rust: test explorer and interpret tests enabled.
- TypeScript/JavaScript: auto-update imports on file move.

**AI tooling:**

- Claude Code: panel location, dangerous permissions skip enabled.
- Copilot: next-edit suggestions on, but code completion disabled for all file types.
- Chat: agents control disabled, stacked sessions orientation.

**Git:** auto-fetch, smart commit, no confirm on sync.

### `home/luke/desktop/zen.nix`

Zen Browser (Firefox fork) with auto-installed extensions:

| Extension | ID |
|-----------|----|
| uBlock Origin | `uBlock0@raymondhill.net` |
| Dark Reader | `addon@darkreader.org` |
| SponsorBlock | `sponsorBlocker@ajay.app` |

All installed via Firefox Add-ons policies (`normal_installed` mode).

### `home/luke/desktop/spicetify.nix`

Spotify customised via spicetify-nix:

- **Extensions:** adblock, hidePodcasts.

### `home/luke/desktop/settings.nix`

A custom settings/debug app built with QuickShell:

- Wrapped as `lu-nix-settings` shell script.
- Has an XDG desktop entry (icon: `preferences-system`, category: Settings).
- QuickShell config sourced from `desktop/settings-app/`.

---

## Custom Services & Automation

### Bootstrap (`home/luke/bootstrap.nix`)

A first-login welcome experience:

1. **Guard:** Checks for `~/.local/state/bootstrap-done` marker; exits if present (use `--force` to override).
2. **DMS suppression:** Creates `.firstlaunch` and changelog markers so DMS doesn't show its own onboarding.
3. **App hiding:** Writes `session.json` to hide nvim, vim, btop, foot-server, ikhal from the DMS launcher.
4. **Status file:** Creates a JSON progress file for the QuickShell UI to read.
5. **Background tasks:** Runs `bootstrap.sh` in the background (editor config, cloud storage setup, etc.).
6. **QuickShell UI:** Launches a QuickShell-based welcome interface that blocks until dismissed.

**Services:**

| Service | Purpose |
|---------|---------|
| `bootstrap` | Oneshot, runs after `graphical-session.target`, 10-minute timeout |
| `lazy-wallpapers` | Downloads remaining wallpaper folders via git sparse-checkout after DMS starts |

DMS and foot-autostart are ordered to start **after** bootstrap completes.

### Cloud Sync (`home/luke/cloud-sync.nix`)

A custom Home Manager module for rclone-based cloud storage sync:

**Options:**

| Option | Type | Default |
|--------|------|---------|
| `enable` | bool | false |
| `provider` | enum: b2, gdrive, onedrive | — |
| `remoteName` | string | `"cloud"` |
| `directories` | list of {remote, local} | `[]` |
| `timerInterval` | string | `"hourly"` |

**Current usage (from `desktop.nix`):**

- Provider: Backblaze B2, remote name: `cloud`.
- Syncs: `Documents` → `~/Documents`, `Pictures` → `~/Pictures`.

**Scripts placed in `~/.local/bin/`:**

- `cloud-sync` — Runs rclone sync for each configured directory (8 transfers, 16 checkers).
- `cloud-sync-setup` — Interactive setup helper; prompts for B2 keys or opens OAuth for Google Drive / OneDrive.

**Systemd integration:**

- `cloud-sync.service` — Oneshot that runs after `network-online.target`. Won't fail boot if sync fails.
- `cloud-sync.timer` — Periodic trigger (default: hourly, persistent).

---

## Development Tooling

### Flake Dev Shell

Available on all systems via `nix develop`:

| Tool | Purpose |
|------|---------|
| Rust toolchain | Stable Rust + clippy, rustfmt, rust-analyzer, wasm32 target |
| clang + lld | LLVM linker for fast Rust builds |
| Node.js 24 | JavaScript runtime |
| pnpm | Node package manager |
| biome | JS/TS formatter/linter |
| cargo-deny | Dependency audit |
| cargo-edit | `cargo add/rm/upgrade` |
| cargo-nextest | Fast test runner |
| bacon | Background Rust checker |
| watchexec | File watcher |
| fd, ripgrep, jq, just | CLI utilities |
| sqlite, openssl, pkg-config | Native build dependencies |
| typescript-language-server | TS LSP |
| vscode-langservers-extracted | HTML/CSS/JSON LSPs |

### NixOS Modules (for NixOS hosts)

**Rust (`modules/development/rust.nix`):** System-wide Rust toolchain, clang, lld, pkg-config, OpenSSL, SQLite. Sets `LIBCLANG_PATH` and `RUST_SRC_PATH`.

**TypeScript (`modules/development/typescript.nix`):** System-wide Node.js and pnpm.

---

## Keybindings Reference

### Hyprland (mod = Super)

#### App Launchers (focus-or-launch)

| Binding | App |
|---------|-----|
| `Super+Return` or `Super+T` | Foot terminal |
| `Super+C` | VSCode |
| `Super+E` | Thunar |
| `Super+W` | Zen Browser (Personal profile) |
| `Super+O` | Obsidian |
| `Super+D` | Discord |
| `Super+G` | Steam |
| `Super+R` | RetroArch |
| `Super+S` | Spotify |

#### Force New Instance

| Binding | App |
|---------|-----|
| `Super+Shift+Return` | New Foot window |
| `Super+Shift+C` | New VSCode window |
| `Super+Shift+E` | New Thunar window |
| `Super+Shift+W` | New Zen window |

#### Window Management

| Binding | Action |
|---------|--------|
| `Super+Tab` | Previous workspace |
| `Alt+Tab` | Focus next window (dwindle) |
| `Super+Ctrl+Return` | Maximise (type 1) |
| `Super+Alt+Return` | Fullscreen (type 0) |
| `Super+Grave` | Toggle special workspace |
| `Super+Shift+Grave` | Move window to special workspace |
| `Super+Alt+Space` | Toggle floating |
| `Alt+F4` or `Super+X` | Kill window (hypr-kill) |

#### Workspace Navigation

| Binding | Action |
|---------|--------|
| `Super+Up` | Previous workspace |
| `Super+Down` | Next workspace |
| `Super+Shift+Up` | Move window to previous workspace |
| `Super+Shift+Down` | Move window to next workspace |

#### Utilities

| Binding | Action |
|---------|--------|
| `Super` (tap) | Toggle DMS spotlight/launcher |
| `Ctrl+Super+[` | Decrease window opacity by 5% |
| `Ctrl+Super+]` | Increase window opacity by 5% |
| Mouse button 276 | Zoom in (0.5 step) |
| Mouse button 275 | Zoom reset |

### Foot Terminal

| Binding | Action |
|---------|--------|
| `Ctrl+C` | Copy to clipboard |
| `Ctrl+Shift+C` | Send SIGINT |
| `Ctrl+V` | Paste from clipboard |
| `Ctrl+F` | Search |
| `Ctrl+Plus/Equal` | Increase font size |
| `Ctrl+Minus` | Decrease font size |
| `Ctrl+0` | Reset font size |
| `Page Up/Down` | Scroll |

### Window Rules

| Class | Rule |
|-------|------|
| Spotify, Code, Obsidian, Foot, Thunar | 95% opacity |
| Cursor, Windsurf, EasyEffects | 90% opacity |
| automata, raia, arcana | Float |
| automata, arcana | Move to special workspace (silent) |
| RetroArch | Render when unfocused |

---

## Build & Deploy Commands

### Home Manager (Arch)

```bash
home-manager switch --flake .#luke
```

The `hms` shell abbreviation runs `home-manager switch --flake .` (infers `#luke` from `$USER`). The explicit `#luke` form is preferred in scripts and documentation.

### NixOS

```bash
sudo nixos-rebuild switch --flake .#desktop
```

### VM (via justfile)

| Command | Description |
|---------|-------------|
| `just vm-build` | Build the vm-dev NixOS VM |
| `just vm-run` | Build and run with a fresh disk |
| `just vm-run-persist` | Build and run preserving disk state |
| `just vm-run-serial` | Run with serial console attached |

The justfile patches the generated VM runner script to use the host's system QEMU instead of the Nix-built one, so that GL passthrough (virgl) works on non-NixOS hosts.

### Formatting

```bash
nix fmt    # runs nixfmt on the flake
```

---

## Known Coupling Points

These are the fragile seams in the config — places where components depend on each other in non-obvious ways. When something breaks, check here first.

### Arch GL ↔ Nix GUI apps

`arch-gl.nix` injects `LIBGL_DRIVERS_PATH`, `__EGL_VENDOR_LIBRARY_DIRS`, and `LD_LIBRARY_PATH` into the DMS and bootstrap services so that Nix-built QuickShell/DMS can use Arch's GPU drivers. If Arch updates Mesa or moves driver paths, DMS will fail to render. Symptom: DMS crashes immediately on start, `journalctl --user -u dms` shows EGL/DRI errors.

### Hyprland ↔ monitor `DP-1`

`hyprland.nix` hardcodes `DP-1,2560x1440@164.06,0x0,2,vrr,1`. On a different machine or if the GPU port changes, Hyprland will either pick the wrong output or fail to configure the display. The fallback line (`,preferred,auto,auto`) catches unknown monitors but at default settings. Override the `monitor` list for new hardware.

### DMS ↔ Hyprland stub configs

Hyprland's config includes `source = ~/.config/hypr/dms/*.conf` for 5 files that DMS generates at runtime. If these files don't exist when Hyprland parses its config, it errors. The activation script in `hyprland.nix` creates empty stubs, and `vm-dev/default.nix` does the same in its session script. If a new DMS config file is added upstream, the stub list must be updated in both places.

### DMS ↔ service ordering on Arch

`arch-gl.nix` binds DMS to `hyprland-session.target` instead of `graphical-session.target` because the Wayland socket doesn't exist until Hyprland is fully started. On logout/login, the old socket vanishes before the new Hyprland is ready — the generous restart limits (10 within 60s) let DMS survive this gap. If DMS still fails after login cycling, check that `hyprland-session.target` is being activated.

### Bootstrap → DMS → foot-autostart ordering

On first login: `bootstrap.service` runs first (suppresses DMS onboarding, sets wallpaper, shows welcome UI). DMS and `foot-autostart` are ordered `After=bootstrap.service`. If bootstrap hangs or fails, DMS and foot won't start. The 10-minute timeout on bootstrap is the safety valve. After first login (`~/.local/state/bootstrap-done` exists), bootstrap is skipped via `ConditionPathExists`.

### Foot ↔ DMS color generation

`foot-autostart` waits up to 15 seconds for DMS to generate `~/.config/foot/dank-colors.ini`, then applies a `[colors]` → `[colors-dark]` rename fix before launching foot. If DMS is slow or the color file format changes, foot either starts with broken colors or doesn't start at all. The `foot-fix-colors` path unit watches for subsequent changes and re-applies the fix.

### VM ↔ host QEMU

The justfile patches the NixOS-generated VM runner to use the host's `qemu-system-x86_64` instead of the Nix-built one. This is required for virgl (GPU passthrough via GTK display) to work on non-NixOS hosts. If the host QEMU is missing or incompatible, the VM won't start. The sed pattern in the justfile assumes the Nix store path format hasn't changed.

### Cloud sync ↔ rclone config

`cloud-sync.service` fails silently if `~/.config/rclone/rclone.conf` doesn't exist or the remote name doesn't match. The `ExecStartPost = true` line prevents this from blocking boot, but sync won't happen until `cloud-sync-setup` is run manually.

---

## Migration Guide

How to bring up a new Arch machine from scratch using this flake.

### 1. Install system prerequisites (pacman)

The Arch-side session and system integration in this config assumes these packages are present.

```bash
# Compositor, session, and Wayland infrastructure
# Hyprland is installed by pacman; Home Manager only writes its configuration
pacman -S hyprland xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland \
          polkit wl-clipboard

# Login manager (pick one — greetd is what NixOS hosts use)
pacman -S greetd greetd-tuigreet
# or: pacman -S sddm

# Audio (PipeWire stack)
pacman -S pipewire pipewire-pulse pipewire-jack wireplumber

# Networking
pacman -S networkmanager

# GL/EGL stack (needed by Nix-built DMS/QuickShell — usually already present)
pacman -S mesa libglvnd

# Terminal and shell (Arch-side, used before HM activates)
pacman -S foot fish

# Qt theming (qt6ct is assumed by hyprland.nix env vars)
pacman -S qt6ct

# Keyring (VSCode and Zen use --password-store=gnome)
pacman -S gnome-keyring

# Docker, git, build tools
pacman -S docker git base-devel github-cli

# Steam (if gaming — also needs multilib repo enabled)
pacman -S steam
```

> **Note:** User applications like Thunar, mpv, pavucontrol, gnome-text-editor, and Obsidian are intentionally installed via Home Manager (Nix), not pacman. They do not need Arch-side packages.

Enable services:

```bash
systemctl enable --now NetworkManager
systemctl enable --now docker
systemctl enable --now greetd   # or sddm
systemctl enable --now pipewire pipewire-pulse wireplumber
```

Add user to required groups:

```bash
usermod -aG wheel,docker,video,audio,networkmanager luke
```

### 2. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable flakes in `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### 3. Clone and activate Home Manager

```bash
git clone <repo-url> ~/Source/lu-nix
cd ~/Source/lu-nix
nix run home-manager -- switch --flake .#luke
```

> This first activation does not require a preinstalled `home-manager` command — `nix run` bootstraps it.

On subsequent runs:

```bash
home-manager switch --flake .#luke
# or use the 'hms' abbreviation once Fish is your active shell
```

### 4. Configure greetd / session

Configure greetd (or your login manager) to launch Hyprland for user `luke`. Example `/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "greeter"
```

Home Manager manages the Hyprland config but not the session launcher on Arch.

### 5. Set up cloud sync

```bash
cloud-sync-setup    # interactive — prompts for B2 application key
cloud-sync          # initial pull of Documents + Pictures
```

### 6. Validate

Run through the [Bring-Up Checklist](#bring-up-checklist) below.

### Known host assumptions

These are easy to forget on a fresh machine:

- Primary desktop monitor is `DP-1` — override in `hyprland.nix` if different
- Arch provides GL/EGL drivers at `/usr/lib/dri` and `/usr/share/glvnd/egl_vendor.d`
- greetd or equivalent starts Hyprland — HM does not manage the login manager
- `gh auth login` must be run before git credential helper works
- VSCode and Zen expect `gnome-keyring` for `--password-store=gnome`

---

## Recovery Guide

### Roll back a Home Manager generation

```bash
# List generations
home-manager generations

# Switch to a specific generation
/nix/var/nix/profiles/per-user/luke/home-manager-<N>-link/activate
```

### Temporarily disable DMS

```bash
systemctl --user stop dms
systemctl --user disable dms
```

Hyprland will continue running without the shell/panel. Re-enable with:

```bash
systemctl --user enable --now dms
```

### Start plain Hyprland (no DMS)

Stop DMS and get a terminal — no config edits needed:

```bash
systemctl --user stop dms
hyprctl dispatch exec foot   # get a terminal without DMS
```

If you need to fully remove DMS from the Hyprland session (temporary debugging only — prefer fixing the declarative config and re-running `home-manager switch`; manual edits to generated config are overwritten on next switch):

```bash
# Back up the generated config, then strip DMS source lines
cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak
sed -i '/source.*dms\//d' ~/.config/hypr/hyprland.conf
# Restore after debugging:
# cp ~/.config/hypr/hyprland.conf.bak ~/.config/hypr/hyprland.conf
```

### Inspect user service failures

```bash
systemctl --user status dms
systemctl --user status bootstrap
systemctl --user status cloud-sync
systemctl --user status foot-autostart
journalctl --user -u dms -n 50
```

### Rebuild the VM baseline

```bash
just vm-run    # fresh disk every time
```

### Debug greetd (NixOS)

```bash
journalctl -u greetd -n 50
# or switch to a TTY: Ctrl+Alt+F2
```

---

## Bring-Up Checklist

Validation after applying the config on a new or rebuilt machine. The **required baseline** must all pass for the system to be usable. Everything else is optional and can be validated later.

> On first login, the bootstrap service may temporarily delay DMS and foot startup while onboarding completes. If DMS or foot don't appear immediately, check `systemctl --user status bootstrap` before investigating further.

### Required baseline

- [ ] Login works (greetd / SDDM / TTY → Hyprland)
- [ ] Hyprland starts and displays wallpaper
- [ ] DMS panel/shell appears
- [ ] DMS spotlight opens on Super tap
- [ ] `Super+Return` — Foot terminal launches with Fish shell
- [ ] `Super+C` — VSCode launches
- [ ] `Super+W` — Zen Browser launches
- [ ] `Super+E` — Thunar launches
- [ ] Copy/paste works between apps (Ctrl+C in Foot, Ctrl+V in VSCode)
- [ ] `xdg-open https://example.com` opens Zen
- [ ] `pavucontrol` opens and shows output device
- [ ] Audio plays through correct output

### Desktop polish

- [ ] DMS clipboard history shows entries
- [ ] GTK apps use adw-gtk3-dark
- [ ] Qt apps use Darkly / DankMatugen colors
- [ ] Foot terminal has DMS-generated color scheme (not fallback)
- [ ] Cursor theme is Adwaita across all apps

### Cloud sync

- [ ] `cloud-sync-setup` completes without error
- [ ] `cloud-sync` pulls Documents and Pictures
- [ ] `systemctl --user status cloud-sync.timer` shows active

### Development

- [ ] `nix develop` enters dev shell
- [ ] `rustc --version` shows expected toolchain
- [ ] `node --version` shows Node.js
- [ ] `cargo test --workspace` passes (in a Rust project)
- [ ] `pnpm build` succeeds (in a Node project)

### Gaming

- [ ] `Super+G` — Steam launches
- [ ] `Super+R` — RetroArch launches with XMB menu
- [ ] gamescope works: `gamescope -- steam`
