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
    self.nixosModules.feature-hardening
    self.nixosModules.feature-system-packages
    self.nixosModules.feature-xdg
    self.nixosModules.feature-nebula
    self.nixosModules.user-brian
    self.nixosModules.user-groups
    inputs.nix-index-database.nixosModules.nix-index
    inputs.srvos.nixosModules.mixins-nix-experimental
    inputs.srvos.nixosModules.mixins-trusted-nix-caches
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ];

  config = {
    # Enable hardening and system packages by default
    features = {
      security.hardening.enable = lib.mkDefault true;
      system.packages.enable = lib.mkDefault true;
      system.xdg.enable = lib.mkDefault true;
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
        trusted-users = [
          "root"
          "brian"
        ];
        auto-optimise-store = true; # Optimise syslinks
        keep-outputs = true; # Keep outputs of derivations
        keep-derivations = true; # Keep derivations
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
          # TODO: Fix this
          sshUser = "bmg";
          sshKey = "/home/brian/.ssh/builder-key";
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
          # TODO: Fix this
          sshUser = "bmg";
          sshKey = "/home/brian/.ssh/builder-key";
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
      useNetworkd = lib.mkForce false;
    };

    programs = {
      ssh = {
        extraConfig = ''
          Host hetzarm
               user bmg
               HostName 65.21.20.242
          Host nephele
               Hostname 65.109.25.143
               Port 22
          host ghaf-net
               user ghaf
               IdentityFile ~/.ssh/builder-key
               #hostname 192.168.10.108 #x1-carbon
               hostname 192.168.10.229 #darter-pro
               #hostname 192.168.10.34 #usb-ethernet
          host ghaf-host
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.2
               proxyjump ghaf-net
          host ghaf-ui
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.3
               proxyjump ghaf-net
          host agx-host
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.10.149
          host vedenemo-builder
               user bmg
               hostname builder.vedenemo.dev
               IdentityFile ~/.ssh/builder-key
          host caelus
               hostname 95.217.167.39
          host uae-lab-node1
               user bmg
               hostname 10.161.5.196
        '';
        knownHosts = {
          hetzarm-ed25519 = {
            hostNames = [ "65.21.20.242" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
          };
          vedenemo-builder = {
            hostNames = [ "builder.vedenemo.dev" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
          };
          nephele = {
            hostNames = [ "65.109.25.143" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwoWKmFa6B9SBci63YG0gaP2kxhXNn1vlMgbky6LjKr";
          };
          caelus = {
            hostNames = [ "95.217.167.39" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHrlodsjLMgGSEM0+NP+0FN7MD6gkySxo7ydKWxP44w";
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
    services.userborn.enable = true;

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
