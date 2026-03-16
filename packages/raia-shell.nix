#
# Nix package for raia-shell — text-mode continuity shell.
#
# Builds from source using a standalone Cargo.toml decoupled from the
# raia workspace (raia-shell has no workspace-internal path deps).
#
# Requires --impure for local source path access.
#
{ pkgs
, raia-shell-src ? builtins.path {
    path = /home/luke/Source/infra/raia/src/raia-shell;
    name = "raia-shell-src";
  }
}:

let
  # Assemble a self-contained source tree:
  # - Cargo.toml and Cargo.lock from lu-nix (standalone, no workspace refs)
  # - Rust source from the raia repo
  src = pkgs.runCommand "raia-shell-src" {} ''
    mkdir -p $out/src
    cp -r ${raia-shell-src}/src/* $out/src/
    cp ${./raia-shell/Cargo.toml} $out/Cargo.toml
    cp ${./raia-shell/Cargo.lock} $out/Cargo.lock
  '';
in
pkgs.rustPlatform.buildRustPackage {
  pname = "raia-shell";
  version = "0.1.0";

  inherit src;
  cargoLock.lockFile = ./raia-shell/Cargo.lock;

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  meta = {
    description = "Text-mode Raia Shell — the first human shell over the continuity runtime";
    license = pkgs.lib.licenses.mit;
    mainProgram = "raia-shell";
  };
}
