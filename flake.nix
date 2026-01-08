# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  description = "First honest attempt to declare a system";

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Our source of packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixpkgs.url = "git+file:////home/brian/projects/code/github.com/NixOS/nixpkgs";

    # Allows us to structure the flake with the NixOS module system
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Get to the bottom of it
    flake-root.url = "github:srid/flake-root";

    # Format all the things
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For preserving compatibility with non-Flake users
    flake-compat = {
      url = "github:nix-community/flake-compat";
      flake = false;
    };

    # To ensure that checks are run locally to enforce cleanliness
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    # Increased productivity for ephemeral environments
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
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

    nix-ai = {
      url = "github:olafkfreund/nix-ai-help";
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
      #url = "git+file:///home/brian/projects/code/github.com/nix-community/nixd";
    };

    fast-flake-update = {
      url = "github:Mic92/fast-flake-update";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    # for provisioning secrets that can be embedded in the configuration
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for deploying remote systems
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gp-gui = {
      #url = "git+file:///home/brian/projects/code/github.com/tiiuae/gp-gui";
      url = "github:brianmcgillion/gp-gui";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        flake-root.follows = "flake-root";
        treefmt-nix.follows = "treefmt-nix";
        git-hooks-nix.follows = "git-hooks-nix";
        devshell.follows = "devshell";
      };
    };
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
          ./modules
          ./home
          ./hosts
          ./nix
          ./packages
        ];

        debug = true;
      };
}
