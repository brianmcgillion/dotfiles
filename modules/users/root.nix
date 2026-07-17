# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Root user SSH configuration
#
# Root is administered with brian's YubiKeys — the key list itself is his
# (modules/users/brian/keys); this module only decides who root trusts.
#
# SSH keys:
# - brian's YubiKey SSH keys (sk-ssh-ed25519), hardware-backed
# - several physical devices, for backup/redundancy
#
# Security considerations:
# - Only key-based authentication (no password)
# - Hardware keys cannot be copied or extracted
# - Physical key presence required for authentication
# - Complements per-host root login policies
# - The software-backed deploy key is NOT granted here; deploy-rs target
#   hosts add it individually (see profile-server and hosts/argus)
#
# Usage:
#   Automatically imported by profile-common
#
# Note: Actual root login is controlled by sshd settings.
# These keys allow root login when PermitRootLogin is enabled.
{
  config,
  lib,
  self,
  ...
}:
{
  users.users.root.openssh.authorizedKeys.keys =
    # YubiKey SSH keys (hardware-backed authentication) — the interactive path.
    self.lib.keys.brian.yubikeys
    # Plus the software deploy key, but only where deploy-rs actually needs
    # it: the node list in nix/deployments.nix is the single source of "is
    # this a deploy target", so adding a node there grants the key with it.
    ++ lib.optional (
      self.deploy.nodes ? ${config.networking.hostName}
    ) self.lib.keys.brian.builderAsRoot;
}
