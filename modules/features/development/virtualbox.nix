# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# VirtualBox virtualisation host
#
# Enables the VirtualBox host (kernel modules, vboxnet0 host-only interface,
# guest additions ISO shipped in the package) plus the Oracle Extension Pack
# for USB 2/3, RDP and PXE boot. Group membership for the user is granted in
# modules/users/brian/nixos.nix (gated on this feature being enabled).
#
# Usage:
#   features.development.virtualbox.enable = true;
#
# Imported by profile-client, not enabled by default: enable it per host.
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.development.virtualbox;
in
{
  options.features.development.virtualbox = {
    enable = lib.mkEnableOption "VirtualBox virtualisation host";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox.host = {
      enable = true;
      # Unfree override, so cache.nixos.org has no build of it: expect a local
      # VirtualBox compile here and on every nixpkgs bump of the package.
      enableExtensionPack = true;
    };
  };
}
