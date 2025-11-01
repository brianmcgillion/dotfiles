# SPDX-License-Identifier: MIT
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
        ];
      };
      overlays = [
        inputs.emacs-overlay.overlays.default
        self.overlays.own-pkgs-overlay
      ];
    };

    nix = {
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        builders-use-substitutes = true;
        build-users-group = "nixbld";
        trusted-users = [
          "root"
          "brian"
        ];
        auto-optimise-store = true;
        keep-outputs = true;
        keep-derivations = true;
      };

      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };

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
          sshUser = "bmg";
          sshKey = "/home/brian/.ssh/builder-key";
        }
      ];

      distributedBuilds = true;
    };

    system.configurationRevision = if (self ? rev) then self.rev else self.dirtyShortRev;

    systemd.services = {
      nix-gc.serviceConfig.Restart = "on-failure";
      NetworkManager-wait-online.enable = false;
    };

    networking = {
      useDHCP = false;
      enableIPv6 = false;
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
               hostname 192.168.10.108
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

    programs.nix-index-database.comma.enable = true;
  };
}
