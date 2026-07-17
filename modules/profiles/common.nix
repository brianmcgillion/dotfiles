# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Common base configuration for all systems
#
# This profile provides the foundation for all NixOS systems in this configuration.
# It includes:
# - Nix daemon configuration with flakes and experimental features
# - Garbage collection and store optimization
# - SSH client configuration with known hosts for the fleet
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
    self.nixosModules.feature-github-token
    self.nixosModules.feature-hardening
    self.nixosModules.feature-nebula
    self.nixosModules.feature-remote-builders
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
      config.allowUnfree = true;
      overlays = [ self.overlays.own-pkgs-overlay ];
    };

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      # Only register actual flake inputs (skip flake=false sources which
      # can't be registered as flakes and may trigger unnecessary fetches)
      registry =
        let
          nonFlakeInputs = [
            "flake-compat"
          ];
        in
        lib.mapAttrs (_: value: { flake = value; }) (
          lib.filterAttrs (name: _: !builtins.elem name nonFlakeInputs) inputs
        );
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

        # Run builds in their own cgroups (better isolation/accounting;
        # also a prerequisite if auto-allocate-uids is ever enabled)
        use-cgroups = true;
      };

      # Store optimisation via the periodic timer (auto-optimise-store is
      # redundant with it and historically lock-contention-prone)
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };
    };

    # Only available when dirty
    system.configurationRevision = if (self ? rev) then self.rev else self.dirtyShortRev;

    security.sudo.wheelNeedsPassword = false;

    # Sometimes nix-gc fails if a store path is still in use.
    # This should fix intermediate issues.
    systemd.services.nix-gc.serviceConfig.Restart = "on-failure";

    # Common network configuration
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    networking = {
      useDHCP = false;
      # Clients default to IPv4-only; servers with native IPv6 (Hetzner)
      # override this per-host.
      enableIPv6 = lib.mkDefault false;
      # Open ports in the firewall?
      firewall.enable = true;
      nftables.enable = true;
    };

    programs = {
      ssh = {
        # SSH known hosts (system-wide; the fleet plus personal infra)
        knownHosts = {
          bmg-sh-gr = {
            hostNames = [ "3.79.116.201" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBiWERbqSD3oSXSAs8VbnKLjCPZZIsAcKWcyI2/lW45K";
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
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # Boot configuration
    # Use systemd-based initrd (scripted initrd is deprecated in 26.05,
    # removed in 26.11)
    boot.initrd.systemd.enable = true;

    # Tie the sops module to the system's ssh keys
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
