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

dev:
  pnpm dev

vm-build:
  nix build .#nixosConfigurations.vm-dev.config.system.build.vm

# Run the VM with system QEMU (required for GL/virgl on non-NixOS hosts)
vm-run: vm-build
  rm -f vm-dev.qcow2
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash

# Run the VM preserving disk state between runs
vm-run-persist: vm-build
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash

# Run the VM with serial console attached
vm-run-serial: vm-build
  sed "s|/nix/store/[^/]*/bin/qemu-system-x86_64|qemu-system-x86_64|" ./result/bin/run-*-vm | bash -s -- -serial mon:stdio
