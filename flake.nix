{
  description = "NixOS + standalone Home Manager flake with Rust and TypeScript development baseline";

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

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
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
          config.allowUnfree = true;
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
    // (let
      system = "x86_64-linux";
      pkgs = mkPkgs system;
      rustToolchain = mkRustToolchain pkgs;
      nodejs = mkNodejs pkgs;

      homeModulesShared = [
        inputs.dms.homeModules.dank-material-shell
        inputs.dms-plugin-registry.modules.default
        inputs.danksearch.homeModules.dsearch
      ];

      mkHost = { path, homeModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs nodejs rustToolchain self;
          };

          modules = [
            inputs.niri.nixosModules.niri
            inputs.dms.nixosModules.dank-material-shell
            inputs.dms.nixosModules.greeter
            home-manager.nixosModules.home-manager
            path
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = homeModulesShared ++ [
                inputs.dms.homeModules.niri
                inputs.niri.homeModules.niri
              ];
              home-manager.extraSpecialArgs = {
                inherit inputs nodejs rustToolchain self;
              };
              home-manager.users.luke = {
                imports = [ ./home/luke ] ++ homeModules;
              };
            }
          ];
        };
    in {
      # Standalone Home Manager for Arch (or any non-NixOS host)
      homeConfigurations.luke = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit inputs nodejs rustToolchain self;
        };

        modules = homeModulesShared ++ [
          ./home/luke
          ./home/luke/desktop.nix
          ./home/luke/gaming.nix
          ./home/luke/productivity.nix
        ];
      };

      # NixOS configurations (kept for VMs and future devices)
      nixosConfigurations.vm-dev = mkHost {
        path = ./hosts/vm-dev;
        homeModules = [
          ./home/luke/desktop.nix
        ];
      };
      nixosConfigurations.desktop = mkHost {
        path = ./hosts/desktop;
        homeModules = [
          ./home/luke/desktop.nix
          ./home/luke/gaming.nix
          ./home/luke/productivity.nix
        ];
      };
    });
}
