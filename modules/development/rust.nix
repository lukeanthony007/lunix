{
  pkgs,
  rustToolchain,
  ...
}:
{
  environment.variables = {
    LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  };

  environment.systemPackages = with pkgs; [
    llvmPackages_latest.clang
    llvmPackages_latest.lld
    openssl
    pkg-config
    rustToolchain
    sqlite
  ];
}
