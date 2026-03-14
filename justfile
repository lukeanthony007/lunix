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
