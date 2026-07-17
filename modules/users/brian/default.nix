# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Brian user - flake-parts module exporting both NixOS and home-manager configs
#
# This module exports:
# - nixosModules.user-brian: System user account, groups, SSH keys, SOPS secrets
# - homeModules.user-profile-brian: Git identity, Doom Emacs config, personal preferences
_: {
  flake = {
    nixosModules.user-brian = ./nixos.nix;
    homeModules.user-profile-brian = ./hm-profile;

    # Brian's public SSH keys, single-sourced (see ./keys/default.nix for what
    # the builder key actually authorizes; the age material for the same
    # YubiKeys lives beside it).
    lib.keys.brian = import ./keys;
  };
}
