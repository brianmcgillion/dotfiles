# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# Binary Ninja - reverse engineering platform
#
# The actual package installation is handled by the home-manager module
# (home/development/binary-ninja.nix) which checks this option via osConfig.
#
# Usage:
#   features.development.binaryninja.enable = true;
{
  lib,
  ...
}:
{
  options.features.development.binaryninja = {
    enable = lib.mkEnableOption "Binary Ninja reverse engineering platform";
  };
}
