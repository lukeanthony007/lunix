#
# Nix package for raia-core — continuity runtime server.
#
# Wraps the pre-built Bun-compiled binary. The binary embeds:
#   - Bun runtime
#   - All TypeScript source (core.ts + raia-cognition/)
#   - NAPI native module (raia-kernel-node, 216MB .node)
#
# Build strategy: bundled Bun compile (bun build --compile).
# The binary is self-contained — only depends on glibc.
#
# To rebuild the binary:
#   cd /path/to/raia && bun build --compile \
#     src/raia-app/src-tauri/scripts/core-entry.ts \
#     --outfile build/bin/raia-core
#
# Requires --impure for local binary path access.
#
{ pkgs
, raia-core-binary ? builtins.path {
    path = /home/luke/Source/infra/raia/build/bin/raia-core;
    name = "raia-core-bin";
  }
}:

pkgs.stdenv.mkDerivation {
  pname = "raia-core";
  version = "0.1.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${raia-core-binary} $out/bin/raia-core
    chmod 0755 $out/bin/raia-core
  '';

  # The Bun-compiled binary embeds JS + NAPI module in ELF sections.
  # Stripping would corrupt the embedded content.
  dontStrip = true;
  dontPatchELF = true;

  # The binary already has a NixOS-compatible interpreter (built by Nix Bun).
  # Only depends on glibc at runtime.
  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  meta = {
    description = "Raia Continuity Runtime — kernel + HTTP API server";
    license = pkgs.lib.licenses.mit;
    mainProgram = "raia-core";
  };
}
