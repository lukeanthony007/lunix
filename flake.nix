{
  description = "NixOS + standalone Home Manager flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
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
        inputs.zen-browser.homeModules.beta
      ];

      mkHost = { path, homeModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs nodejs rustToolchain self;
          };

          modules = [
            home-manager.nixosModules.home-manager
            path
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = homeModulesShared;
              home-manager.extraSpecialArgs = {
                inherit inputs nodejs rustToolchain self;
              };
              home-manager.users.luke = {
                imports = [ ./home/luke ] ++ homeModules;
              };
            }
          ];
        };
      # --- Raia appliance packages ---

      # raia-core stub for boot-path validation (fallback when real core unavailable)
      raia-core-stub = import ./packages/raia-core-stub.nix { inherit pkgs; };

      # Real raia-shell built from source (requires --impure)
      raia-shell-pkg = import ./packages/raia-shell.nix { inherit pkgs; };

      # Real raia-core built from source (requires --impure)
      raia-core-pkg = import ./packages/raia-core.nix { inherit pkgs; };

      # Appliance host builder — separate from mkHost because it needs
      # different specialArgs and does not include zen-browser or DMS.
      mkAppliance = { raia-core-command ? "${raia-core-stub}/bin/raia-core-stub"
                    , raia-shell-package ? pkgs.hello  # placeholder; override with real package
                    , hostPath ? ./hosts/appliance
                    , applianceUser ? "luke"
                    }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs nodejs rustToolchain self;
            inherit raia-core-command raia-shell-package applianceUser;
          };

          modules = [
            home-manager.nixosModules.home-manager
            hostPath
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs nodejs rustToolchain self;
              };
              home-manager.users.${applianceUser} = {
                imports = [
                  ./home/luke
                  ./home/luke/appliance.nix
                ];
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
          ./home/luke/desktop/hyprland-vm.nix
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

      # Raia continuity appliance — stub core (for eval/CI, no --impure needed)
      nixosConfigurations.appliance = mkAppliance {};

      # Raia continuity appliance — real runtime (requires --impure)
      nixosConfigurations.appliance-real = mkAppliance {
        raia-core-command = "${raia-core-pkg}/bin/raia-core";
        raia-shell-package = raia-shell-pkg;
      };

      # Raia continuity appliance — bare-metal target (requires --impure)
      nixosConfigurations.appliance-bare = mkAppliance {
        hostPath = ./hosts/appliance-bare;
        raia-core-command = "${raia-core-pkg}/bin/raia-core";
        raia-shell-package = raia-shell-pkg;
      };
    });
}
