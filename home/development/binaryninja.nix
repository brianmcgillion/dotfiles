# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# Personal Binary Ninja bits that are not part of the package.
#
# The package, its plugin Python dependencies and the Sidekick venv all live in
# seclab-pkgs (nixosModules/homeModules.binaryninja). This adds the two things
# that module leaves out: the colour scheme and the TMS320C28x plugin.
#
# Binary Ninja reads themes and plugins from its user folder and never writes
# to them, so read-only store symlinks are safe inside ~/.binaryninja even
# though the GUI owns the rest of that directory.
#
# Selecting the theme is still a one-time GUI step:
#   Edit > Preferences > Settings > search "Theme" > Dracula
{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = osConfig.features.development.binaryninja;

  # Pinned to a commit rather than a branch: the raw URL is unversioned, so a
  # `main` reference would drift out from under the hash the way the upstream
  # Binary Ninja logo did.
  dracula = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dracula/binary-ninja/3e458597aac3ef7d232ac2f61a3f4e5a4e21513a/theme/Dracula.bntheme";
    hash = "sha256-n/L1oCtc6xVVjauLRgp2KLosiyXhmmHx4xPqID3CgU8=";
  };
in
{
  home.file = lib.mkIf cfg.enable {
    ".binaryninja/themes/Dracula.bntheme".source = dracula;
    # From seclab-pkgs' overlay, applied in profiles/common.nix. Its $out is
    # the plugin directory itself, so the whole derivation links into place.
    ".binaryninja/plugins/tms320c28x".source = pkgs.tms320c28x-binja;
  };
}
