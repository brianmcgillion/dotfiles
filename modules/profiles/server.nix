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
# - Home-manager integration for minimal user environment
# - srvos server optimizations
#
# Note: the bootloader is configured per-host (the Hetzner hosts use GRUB
# installed as removable EFI media).
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
    # keep-sorted start
    ./common.nix
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.roles-nix-remote-builder
    inputs.srvos.nixosModules.server
    self.nixosModules.feature-fail2ban
    self.nixosModules.feature-sshd
    self.nixosModules.user-root
    # keep-sorted end
    {
      # Who may use this server as a nix remote builder. srvos locks the key
      # down to `restrict,command="nix-daemon --stdio"` on its own user.
      # NOTE: no host currently lists nubes/caelus in nix.buildMachines, so
      # this grant is presently unused.
      roles.nix-remote-builder.schedulerPublicKeys = [ self.lib.keys.brian.builder ];
    }
  ];

  config = {
    # Set profile target
    common.profile.target = "server";

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
  };
}
