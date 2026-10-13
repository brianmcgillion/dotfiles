# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# Forensic image tooling
#
# Installs libewf (ewfinfo, ewfexport, ewfmount, ewfacquire, ewfverify) for
# working with Expert Witness Compression Format (E01) images. ewfmount needs
# the fuse-enabled build from own-pkgs-overlay (packages/default.nix).
#
# Usage:
#   features.development.forensics.enable = true;
#
# Imported by profile-client, not enabled by default: enable it per host.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.forensics;
in
{
  options.features.development.forensics = {
    enable = lib.mkEnableOption "forensic image tooling";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.libewf
    ];
  };
}
