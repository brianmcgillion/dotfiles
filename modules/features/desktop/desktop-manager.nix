# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# GNOME desktop environment
#
# Configures GNOME as the desktop environment with GDM display manager.
# Includes opinionated package exclusions to reduce bloat.
#
# Features:
# - GNOME desktop environment
# - GDM display manager
# - X11 window system
# - Excludes unwanted GNOME applications (tour, epiphany, evolution, etc.)
#
# Usage:
#   features.desktop.desktop-manager.enable = true;
#
# Enabled by default in: profile-client
#
# Note: Requires features.desktop.audio for full functionality
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.desktop-manager;
in
{
  options.features.desktop.desktop-manager = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver.enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.gnome.excludePackages = [
      pkgs.gnome-tour
      pkgs.epiphany
      pkgs.evolution
      pkgs.evolutionWithPlugins
      pkgs.evolution-data-server
      pkgs.geary
      pkgs.gnome-music
      pkgs.gnome-contacts
      pkgs.cheese
    ];
  };
}
