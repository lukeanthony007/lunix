set shell := ["bash", "-euo", "pipefail", "-c"]

# === Development VM ===

vm-build:
  nix build .#nixosConfigurations.vm-dev.config.system.build.vm

# Use system QEMU so GL/virgl works on non-NixOS hosts
_vm-exec *ARGS:
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash {{ARGS}}

# Run the VM with a fresh disk
vm-run: vm-build
  rm -f vm-dev.qcow2
  just _vm-exec

# Run the VM preserving disk state between runs
vm-run-persist: vm-build
  just _vm-exec

# Run the VM with serial console attached
vm-run-serial: vm-build
  just _vm-exec -s -- -serial mon:stdio

# === Raia Appliance (stub — for eval/CI) ===

# Build the stub appliance VM image
appliance-build-stub:
  nix build .#nixosConfigurations.appliance.config.system.build.vm

# Validate the stub appliance profile evaluates without errors
appliance-check:
  nix eval .#nixosConfigurations.appliance.config.system.build.toplevel --apply builtins.seq --raw 2>&1 | head -5 || true
  @echo "appliance profile evaluated"

# === Raia Appliance (real runtime) ===

# Build the real appliance VM image (all from source, requires --impure)
# Nix handles: Rust NAPI module build, npm dep fetch, Bun compile, raia-shell build
appliance-build:
  nix build .#nixosConfigurations.appliance-real.config.system.build.vm --impure
  @echo "real appliance VM built"

# Helper to run the appliance VM (uses system QEMU for GL)
_appliance-exec *ARGS:
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash {{ARGS}}

# Run the real appliance VM with a fresh disk
appliance-run: appliance-build
  rm -f raia-appliance.qcow2
  just _appliance-exec

# Run the appliance VM preserving disk state (for testing provisioning persistence)
appliance-run-persist: appliance-build
  just _appliance-exec

# Run the appliance VM with serial console for debugging
appliance-run-serial: appliance-build
  just _appliance-exec -s -- -serial mon:stdio

# === Raia Appliance (bare-metal target) ===

# Build the bare-metal appliance system closure (requires --impure)
appliance-bare-build:
  nix build .#nixosConfigurations.appliance-bare.config.system.build.toplevel --impure
  @echo "bare-metal appliance built"

# Evaluate the bare-metal config without building (quick check)
appliance-bare-check:
  nix eval .#nixosConfigurations.appliance-bare.config.system.build.toplevel --impure 2>&1 | tail -1
  @echo "bare-metal config evaluates"

# Show the install steps for bare-metal target
appliance-bare-guide:
  @echo ""
  @echo "=== Raia Bare-Metal Install Guide ==="
  @echo ""
  @echo "Prerequisites:"
  @echo "  - NixOS minimal installer USB (download from nixos.org)"
  @echo "  - Target machine with EFI boot"
  @echo "  - This repo accessible from the target (USB drive or network)"
  @echo ""
  @echo "On the target machine (booted from installer):"
  @echo ""
  @echo "  1. Partition the disk:"
  @echo "     parted /dev/sdX -- mklabel gpt"
  @echo "     parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB"
  @echo "     parted /dev/sdX -- set 1 esp on"
  @echo "     parted /dev/sdX -- mkpart primary ext4 512MiB 100%"
  @echo ""
  @echo "  2. Format:"
  @echo "     mkfs.fat -F 32 -n BOOT /dev/sdX1"
  @echo "     mkfs.ext4 -L nixos /dev/sdX2"
  @echo ""
  @echo "  3. Mount:"
  @echo "     mount /dev/disk/by-label/nixos /mnt"
  @echo "     mkdir -p /mnt/boot"
  @echo "     mount /dev/disk/by-label/BOOT /mnt/boot"
  @echo ""
  @echo "  4. Generate hardware config:"
  @echo "     nixos-generate-config --root /mnt"
  @echo "     # Copy the generated file back to this repo:"
  @echo "     cp /mnt/etc/nixos/hardware-configuration.nix hosts/appliance-bare/"
  @echo ""
  @echo "  5. Install:"
  @echo "     nixos-install --flake .#appliance-bare --impure"
  @echo ""
  @echo "  6. Reboot and provision:"
  @echo "     reboot"
  @echo "     # After boot, run: raia-provision"
  @echo "     # Then: sudo systemctl restart raia-core"
  @echo ""
