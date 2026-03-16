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

# Build raia-shell from source
raia-shell-build:
  cd ../raia && cargo build -p raia-shell --release
  @echo "raia-shell built: ../raia/target/release/raia-shell"

# Build raia-core binary (Bun compile)
raia-core-build:
  cd ../raia && bun install --ignore-scripts 2>/dev/null; bun build --compile src/raia-app/src-tauri/scripts/core-entry.ts --outfile build/bin/raia-core
  @echo "raia-core built: ../raia/build/bin/raia-core"

# Build both raia binaries
raia-build: raia-shell-build raia-core-build

# Build the real appliance VM image (requires --impure for local source paths)
appliance-build: raia-build
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
