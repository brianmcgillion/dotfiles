# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Docker containerization platform
#
# Enables the (rootful) Docker daemon with weekly auto-prune and installs
# docker-compose. Group membership for the user is granted in
# modules/users/brian/nixos.nix (gated on this feature being enabled).
#
# Usage:
#   features.development.docker.enable = true;
#
# Enabled by default in: profile-client
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.docker;
in
{
  options.features.development.docker = {
    enable = lib.mkEnableOption "Docker containerization platform";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    environment.systemPackages = [
      pkgs.docker-compose
    ];
  };
}
