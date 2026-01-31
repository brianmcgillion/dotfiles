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

    # Fix GDM permission errors for session data directories
    # GDM and gdm-greeter users need these directories for session management, ICC profiles, ibus, gnome-shell, and keyring
    # Use 0775 for directories where gdm-greeter (in gdm group) needs write access
    systemd.tmpfiles.rules = [
      "d /run/gdm/.local 0775 gdm gdm -"
      "d /run/gdm/.local/share 0775 gdm gdm -"
      "d /run/gdm/.local/share/icc 0775 gdm gdm -"
      "d /run/gdm/.local/share/gnome-shell 0775 gdm gdm -"
      "d /run/gdm/.local/share/keyrings 0770 gdm gdm -"
      "d /run/gdm/.cache 0775 gdm gdm -"
      "d /run/gdm/.cache/ibus 0775 gdm gdm -"
      "d /run/gdm/.config 0775 gdm gdm -"
      "d /run/gdm/.config/ibus 0775 gdm gdm -"
    ];

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
