# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
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
    self.nixosModules.user-root
    self.nixosModules.scripts
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.mixins-mdns
    inputs.srvos.nixosModules.roles-nix-remote-builder
    inputs.home-manager.nixosModules.home-manager
    {
      # TODO: set the key programmatically
      roles.nix-remote-builder.schedulerPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu6O3swRVWAjP7J8iYGT6st7NAa+o/XaemokmtKdpGa builder key"
      ];
    }
  ];

  config = {
    # Enable server features by default
    features = {
      security = {
        sshd.enable = lib.mkDefault true;
        fail2ban.enable = lib.mkDefault true;
      };
    };

    # Server-specific services
    services = {
      avahi.enable = false;
    };

    # DNS configuration
    networking.nameservers = [
      # keep-sorted start
      "1.1.1.1"
      "8.8.4.4"
      "8.8.8.8"
      # keep-sorted end
    ];

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
