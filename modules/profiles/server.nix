# SPDX-License-Identifier: MIT
# Server (headless) profile
#
# This profile configures systems for headless server operation.
# It extends the common profile with server-specific features.
#
# Included features:
# - OpenSSH server with hardened configuration
# - fail2ban intrusion prevention
# - Minimal package set (no graphical environment)
# - GRUB bootloader (legacy BIOS/MBR by default)
# - Home-manager integration for minimal user environment
# - srvos server optimizations
#
# Usage:
#   imports = [ self.nixosModules.profile-server ];
#
# Enabled features by default:
#   - features.security.sshd
#   - features.security.fail2ban
#
# Typical use cases:
#   - Dedicated servers (Hetzner, cloud VMs)
#   - Lighthouse nodes for Nebula overlay networks
#   - Build machines
#   - Headless infrastructure
{
  self,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./common.nix
    self.nixosModules.feature-sshd
    self.nixosModules.feature-fail2ban
    self.nixosModules.scripts
    inputs.srvos.nixosModules.server
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    # Enable server features by default
    features = {
      security = {
        sshd.enable = lib.mkDefault true;
        fail2ban.enable = lib.mkDefault true;
      };
    };

    # Bootloader for legacy BIOS/MBR
    boot.loader.grub = {
      enable = lib.mkDefault true;
      efiSupport = lib.mkDefault false;
    };

    # Server-specific services
    services = {
      openssh.startWhenNeeded = lib.mkDefault true;
    };

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs self;
      };
      users.brian = {
        imports = [
          ../../home/profiles/server.nix
          inputs.nix-index-database.homeModules.nix-index
        ];
      };
    };
  };
}
