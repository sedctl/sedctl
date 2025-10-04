{
  description = "sedctl project";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # taken from fenix monthly 2025-07-01
    nixpkgs.url = "github:nixos/nixpkgs/3016b4b15d13f3089db8a41ef937b13a9e33a8df";
    # fenix monthly 2025-07-01
    fenix.url = "github:nix-community/fenix/61b4f1e21bd631da91981f1ed74c959d6993f554";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: let
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    overlays.default = final: prev: rec {
      system = final.stdenv.hostPlatform.system;

      rustToolchainCI = (with inputs.fenix.packages.${system};
        combine [
          stable.rustc
          stable.cargo
          latest.rustfmt
        ]
      );
      rustToolchainDev = (with inputs.fenix.packages.${system};
        combine [
          stable.rustc
          stable.cargo
          stable.rust-analyzer
          latest.rustfmt
          prev.cargo-expand
        ]
      );
      rustToolchainStable = (with inputs.fenix.packages.${system};
        combine [
          stable.rustc
          stable.cargo  
        ]
      );
      rustToolchainNightly = (with inputs.fenix.packages.${system};
        combine [
          latest.rustc
          latest.cargo
          latest.rust-analyzer
          latest.rustfmt
          prev.cargo-expand
        ]
      );
    };

    devShells = forAllSystems (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in rec {
      default = dev;

      dev = pkgs.mkShell {
        packages = with pkgs; [
          rustToolchainDev
          evcxr
        ];
      };
      ci = pkgs.mkShell {
        packages = with pkgs; [
          rustToolchainCI
        ];
      };
    });
  };
}


