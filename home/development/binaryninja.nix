# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# Personal Binary Ninja bits that are not part of the package.
#
# The package, its plugin Python dependencies and the Sidekick venv all live in
# seclab-pkgs (nixosModules/homeModules.binaryninja). This is only the colour
# scheme, which is a preference rather than something to ship to other hosts.
#
# Binary Ninja reads themes from the `themes` subdirectory of its user folder
# and never writes them, so a read-only store symlink is safe inside
# ~/.binaryninja even though the GUI owns the rest of that directory.
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
  home.file.".binaryninja/themes/Dracula.bntheme" = lib.mkIf cfg.enable {
    source = dracula;
  };
}
