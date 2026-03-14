set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just check

nix-lock:
  nix flake lock

bootstrap:
  corepack enable
  pnpm install

check:
  cargo test --workspace
  pnpm check

fmt:
  cargo fmt --all
  pnpm exec biome format --write .

lint:
  cargo clippy --workspace --all-targets --all-features -- -D warnings
  pnpm exec biome check .

dev:
  pnpm dev

vm-build:
  nix build .#nixosConfigurations.vm-dev.config.system.build.vm

# Run the VM with default GTK frontend (primary validation path)
vm-run: vm-build
  ./result/bin/run-*-vm

# Run the VM with serial console attached (for diagnostics alongside GTK)
vm-run-serial: vm-build
  ./result/bin/run-*-vm -serial mon:stdio

# Run the VM using system QEMU (needed for GL/virgl on non-NixOS hosts)
vm-run-gl: vm-build
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash -s -- -serial mon:stdio
