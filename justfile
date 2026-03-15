set shell := ["bash", "-euo", "pipefail", "-c"]

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
