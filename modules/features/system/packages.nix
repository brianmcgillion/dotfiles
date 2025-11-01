# SPDX-License-Identifier: MIT
# System-wide utility packages
#
# Installs essential command-line tools and utilities available system-wide.
# These are tools commonly needed for system administration and development.
#
# Included packages:
# - nixfmt-rfc-style: Nix code formatter
# - cachix: Binary cache management
# - wget, curl: HTTP clients
# - git: Version control
# - htop: Interactive process viewer
# - nix-info: System information for Nix debugging
# - wireguard-tools: VPN management (wg, wg-quick)
# - tree: Directory tree visualization
# - file: File type identification
# - binutils: Binary utilities (objdump, nm, etc.)
# - lsof: List open files
# - dnsutils: DNS tools (dig, nslookup)
# - netcat: Network swiss army knife
# - nix-tree: Visualize Nix store dependencies
# - zellij: Terminal multiplexer
# - devenv: Development environment manager
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
    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      cachix
      wget
      curl
      git
      htop
      nix-info
      wireguard-tools
      tree
      file
      binutils
      lsof
      dnsutils
      netcat
      nix-tree
      zellij
      devenv
    ];
  };
}
