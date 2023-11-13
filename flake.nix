# SPDX-License-Identifier: MIT
{
  description = "First honest attempt to declare a system";

  inputs = {
    # Nix Packages, following unstable (rolling release)
    nixpkgs.url = "nixpkgs/nixos-unstable"; # primary nixpkgs

    # Make the system more modular
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";

    # Formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For preserving compatibility with non-Flake systems
    # Useful for the first bootstrap from a clean nixos install
    flake-compat = {
      url = "github:nix-community/flake-compat";
      flake = false;
    };

    # dotfiles style package management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Track more recent emacs additions e.g. native compiled
    nixos-hardware.url = "github:nixos/nixos-hardware";

    #TODO re-enable later
    # for provisioning secrets that can be embedded in the configuration
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nixpkgs-stable.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake
    {
      inherit inputs;
      specialArgs = {
        inherit (nixpkgs) lib;
      };
    } {
      systems = [
        "x86_64-linux"
        #"aarch64-linux"
        #"aarch64-darwin"
      ];

      imports = [
        ./home
        ./hosts
        ./nix
        ./nixos
        ./users
      ];
    };
}
# }: let
#   user = "brian";
#   system = "x86_64-linux";
#   #pkgs = import <nixpkgs> {};
# in {
#   # Ensure that nix fmt will format the project correctly
#   formatter.${system} = alejandra.defaultPackage.${system};
#   nixosConfigurations = (
#     # for NixOS based system
#     import ./hosts {
#       # imports ./hosts/default.nix
#       inherit (nixpkgs) lib;
#       inherit inputs nixpkgs home-manager user nixos-hardware sops-nix alejandra;
#     }
#   );
#   devShell."${system}" = import ./shell.nix {inherit nixpkgs;};
# };
#}

