# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Common base configuration for all systems
#
# This profile provides the foundation for all NixOS systems in this configuration.
# It includes:
# - Nix daemon configuration with flakes and experimental features
# - Distributed build machines setup
# - Garbage collection and store optimization
# - SSH client configuration with known hosts
# - SOPS secrets management
# - Disko disk management support
# - Basic security hardening
# - System-wide packages
# - XDG compliance
# - nix-index database integration
#
# Usage:
#   This profile is automatically imported by both client and server profiles.
#   It should not typically be imported directly by host configurations.
#
# Enabled features by default:
#   - features.security.hardening
#   - features.system.packages
#   - features.system.xdg
{
  self,
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    # keep-sorted start
    inputs.disko.nixosModules.disko
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops-nix.nixosModules.sops
    inputs.srvos.nixosModules.mixins-nix-experimental
    inputs.srvos.nixosModules.mixins-trusted-nix-caches
    self.nixosModules.feature-hardening
    self.nixosModules.feature-nebula
    self.nixosModules.feature-nix-settings
    self.nixosModules.feature-system-packages
    self.nixosModules.feature-xdg
    self.nixosModules.user-brian
    self.nixosModules.user-groups
    # keep-sorted end
  ];

  options = {
    common.profile.target = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      example = "client";
      description = ''
        Profile target type determining which features are enabled by default.
        - "client": Desktop/laptop systems with GUI, audio, and development tools
        - "server": Headless systems with minimal packages and server-focused features
        Set automatically by importing profile-client or profile-server.
      '';
    };

    common.remoteBuild = {
      sshUser = lib.mkOption {
        type = lib.types.str;
        example = "builder";
        description = ''
          SSH username for connecting to remote Nix build machines.
          This user must have permission to run Nix builds on the remote system.
          Used by both deploy-rs and nix.buildMachines configuration.
        '';
      };

      sshKey = lib.mkOption {
        type = lib.types.path;
        example = "/home/user/.ssh/builder-key";
        description = ''
          Path to SSH private key for authenticating to remote build machines.
          The corresponding public key must be in the authorized_keys of the remote builder user.
          Should have restrictive permissions (0600) for security.
        '';
      };
    };
  };

  config = {
    # Enable hardening and system packages by default
    features = {
      security.hardening.enable = lib.mkDefault true;
      system = {
        packages.enable = lib.mkDefault true;
        xdg.enable = lib.mkDefault true;
      };
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "qtwebengine-5.15.19" # needed for globalprotect-vpn
          "jitsi-meet-1.0.8792"
        ];
      };
      overlays = [
        inputs.emacs-overlay.overlays.default
        self.overlays.own-pkgs-overlay
      ];
    };

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];

        # Avoid copying unnecessary stuff over SSH
        builders-use-substitutes = true;
        build-users-group = "nixbld";
        trusted-users = [ "root" ];
        auto-optimise-store = true; # Optimise syslinks
        keep-outputs = true; # Keep outputs of derivations
        keep-derivations = true; # Keep derivations

        # Enable cgroups for auto-allocate-uids to work properly
        # This allows Nix to dynamically allocate UIDs for builds instead of
        # using pre-created nixbld users
        use-cgroups = true;
      };

      # Garbage collection
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };

      # https://nixos.wiki/wiki/Distributed_build#NixOS
      buildMachines = [
        {
          hostName = "hetzarm";
          system = "aarch64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          inherit (config.common.remoteBuild) sshUser;
          inherit (config.common.remoteBuild) sshKey;
        }
        {
          hostName = "vedenemo-builder";
          system = "x86_64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          inherit (config.common.remoteBuild) sshUser;
          inherit (config.common.remoteBuild) sshKey;
        }
      ];

      distributedBuilds = true;
    };

    # Only available when dirty
    system.configurationRevision = if (self ? rev) then self.rev else self.dirtyShortRev;

    security.sudo.wheelNeedsPassword = false;

    systemd.services = {
      # Sometimes it fails if a store path is still in use.
      # This should fix intermediate issues.
      nix-gc.serviceConfig.Restart = "on-failure";

      # https://github.com/NixOS/nixpkgs/issues/180175
      NetworkManager-wait-online.enable = false;
    };

    # Common network configuration
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    networking = {
      useDHCP = false;
      enableIPv6 = false;
      # Open ports in the firewall?
      firewall.enable = true;
      nftables.enable = true;
    };

    programs = {
      ssh = {
        # SSH known hosts (system-wide, needed for build machines and all users)
        knownHosts = {
          hetzarm = {
            hostNames = [ "65.21.20.242" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
          };
          vedenemo-builder = {
            hostNames = [ "builder.vedenemo.dev" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
          };
          nubes = {
            hostNames = [
              "nubes"
              "nubes.pantheon.bmg.sh"
              "10.99.99.4"
              "65.108.111.248"
            ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKesx/AKktmMQm6PdBBL+G4M62XKcpFwhBOzHU393b3r";
          };
          caelus = {
            hostNames = [
              "caelus"
              "caelus.pantheon.bmg.sh"
              "10.99.99.1"
              "95.217.167.39"
            ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHrlodsjLMgGSEM0+NP+0FN7MD6gkySxo7ydKWxP44w";
          };
          arcadia = {
            hostNames = [
              "arcadia"
              "arcadia.pantheon.bmg.sh"
              "10.99.99.2"
            ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEiajFgF+LqkBNeVWzIU7+qyoDLnci1MCH6rBemnHur+";
          };
          minerva = {
            hostNames = [
              "minerva"
              "minerva.pantheon.bmg.sh"
              "10.99.99.3"
            ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHfhmdcNJ2PFosRHjzjucWcoa3Ri8OUONzs+S/orx2C";
          };
          argus = {
            hostNames = [
              "argus"
              "argus.pantheon.bmg.sh"
              "10.99.99.5"
            ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvQrrjqRRqg5GPwBEIcu/3lb4p1t0C2P+A+qe4CUn9i";
          };
        };
      };
      command-not-found.enable = false;
    };

    programs = {
      nix-index-database.comma.enable = true;
      nix-ld.enable = true;
    };

    # User management
    # Contents of the user and group files will be replaced on system activation
    # Ref: https://search.nixos.org/options?channel=unstable&show=users.mutableUsers
    users.mutableUsers = false;

    # Enable userborn to take care of managing the default users and groups
    services = {
      userborn.enable = true;
    };

    # Hardware
    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    # Boot configuration
    boot = {
      # Use the bleeding edge kernel
      kernelPackages = pkgs.linuxPackages_latest;
      binfmt.emulatedSystems = [
        "riscv64-linux"
        "aarch64-linux"
      ];
    };

    # Tie the sops module to the system's ssh keys
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
