# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# System-wide utility packages
#
# Essential command-line tools for system administration and development,
# available on every host (clients and servers). See the keep-sorted list
# below for the authoritative set — this header deliberately does not
# repeat it.
#
# wireguard-tools lives in the wireguard feature (client-only); dig comes
# from dnsutils here.
#
# Usage:
#   features.system.packages.enable = true;
#
# Enabled by default in: profile-common (applies to all systems)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.system.packages;
in
{
  options.features.system.packages = {
    enable = lib.mkEnableOption "system-wide packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      # keep-sorted start
      pkgs.binutils
      pkgs.cachix
      pkgs.curl
      pkgs.devenv
      pkgs.dnsutils
      pkgs.file
      pkgs.git
      pkgs.htop
      pkgs.lsof
      pkgs.netcat
      pkgs.nix-info
      pkgs.nix-output-monitor
      pkgs.nix-tree
      pkgs.nixfmt
      pkgs.tree
      pkgs.wget
      pkgs.zellij
      # keep-sorted end
    ];
  };
}
