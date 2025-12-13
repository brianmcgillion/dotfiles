# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Brian's user-specific home-manager configuration
#
# This module contains Brian's personal settings that should not be
# shared with other users:
# - Git identity and configuration
# - Doom Emacs personal configuration repository (client systems only)
# - Other user-specific preferences
#
# Usage:
#   Import this module via self.homeModules.user-profile-brian
#
# Options:
#   userProfile.enableEmacs - Whether to enable Brian's Emacs config (default: false)
{ lib, ... }:
{
  options.userProfile.enableEmacs = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Brian's Doom Emacs configuration";
  };

  imports = [
    ./git.nix
    ./emacs.nix
  ];
}
