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
      url = "github:inclyc/flake-compat";
      flake = false;
    };

    # dotfiles style package management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Disko for disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # index of the nixpkgs
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixd lsp integration
    nixd = {
      url = "github:nix-community/nixd";
    };

    # for provisioning secrets that can be embedded in the configuration
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    # Used for deploying remote systems
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    #TODO add the following for more managable configs
    #https://github.com/ehllie/ez-configs/tree/main
    # Part of flake-parts modules
    # See example usage
    # https://github.com/ehllie/dotfiles/tree/main
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = {
          inherit (nixpkgs) lib;
        };
      }
      {
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
          ./packages
        ];

        debug = true;
      };
}
