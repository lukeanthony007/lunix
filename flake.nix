{
  description = "VM-first NixOS flake with a Rust and TypeScript development baseline";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    self,
    flake-utils,
    home-manager,
    nixpkgs,
    rust-overlay,
    ...
  }:
    let
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

      mkRustToolchain = pkgs:
        pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "clippy"
            "llvm-tools-preview"
            "rust-analyzer"
            "rust-src"
            "rustfmt"
          ];
          targets = [
            "wasm32-unknown-unknown"
          ];
        };

      mkNodejs = pkgs: pkgs.nodejs_24 or pkgs.nodejs;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = mkPkgs system;
        rustToolchain = mkRustToolchain pkgs;
        nodejs = mkNodejs pkgs;
      in
      {
        formatter = pkgs.nixfmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bacon
            biome
            cargo-deny
            cargo-edit
            cargo-nextest
            fd
            git
            jq
            just
            llvmPackages_latest.clang
            llvmPackages_latest.lld
            nodejs
            openssl
            pkg-config
            pnpm
            ripgrep
            rustToolchain
            sqlite
            typescript-language-server
            vscode-langservers-extracted
            watchexec
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"

            echo "lu-nix dev shell"
            echo "Rust: $(rustc --version)"
            echo "Node: $(node --version)"
            echo "pnpm: $(pnpm --version)"
          '';
        };
      }
    )
    // {
      nixosConfigurations.vm-dev =
        let
          system = "x86_64-linux";
          pkgs = mkPkgs system;
          rustToolchain = mkRustToolchain pkgs;
          nodejs = mkNodejs pkgs;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs nodejs rustToolchain self;
          };

          modules = [
            inputs.niri.nixosModules.niri
            home-manager.nixosModules.home-manager
            ./hosts/vm-dev/default.nix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs nodejs rustToolchain self;
              };
              home-manager.users.luke = import ./home/luke;
            }
          ];
        };
    };
}
