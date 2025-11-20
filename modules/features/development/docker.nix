# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Docker containerization platform
#
# Enables Docker daemon and configures user access for container development.
#
# Features:
# - Docker daemon with rootless mode support
# - User automatically added to docker group
# - Container networking and storage configuration
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

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
