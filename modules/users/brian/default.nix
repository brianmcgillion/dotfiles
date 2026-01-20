# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Brian user - flake-parts module exporting both NixOS and home-manager configs
#
# This module exports:
# - nixosModules.user-brian: System user account, groups, SSH keys, SOPS secrets
# - homeModules.user-profile-brian: Git identity, Doom Emacs config, personal preferences
_: {
  flake = {
    nixosModules.user-brian = import ./nixos.nix;
    homeModules.user-profile-brian = import ./hm-profile;
  };
}
