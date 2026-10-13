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

    # Qt6 apps load qtbase's libqgtk3 platform theme on GNOME, and GTK3's
    # file chooser aborts the process if its GSettings schemas are absent —
    # GNOME 50 adds no gtk3 schema dir to XDG_DATA_DIRS.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    ];

    # Fix GDM permission errors for session data directories (the greeter
    # runs as the gdm user on NixOS) — ICC profiles, ibus, gnome-shell and
    # keyring want these to exist.
    # /run/gdm/.config is NOT listed: the upstream GDM module already
    # declares it and a second rule for the same path only produces
    # systemd-tmpfiles duplicate-line warnings.
    systemd.tmpfiles.rules = [
      "d /run/gdm/.local 0755 gdm gdm -"
      "d /run/gdm/.local/share 0755 gdm gdm -"
      "d /run/gdm/.local/share/icc 0755 gdm gdm -"
      "d /run/gdm/.local/share/gnome-shell 0755 gdm gdm -"
      "d /run/gdm/.local/share/keyrings 0700 gdm gdm -"
      "d /run/gdm/.cache 0755 gdm gdm -"
      "d /run/gdm/.cache/ibus 0755 gdm gdm -"
      "d /run/gdm/.config/ibus 0755 gdm gdm -"
    ];

    # Only packages GNOME actually installs by default belong here —
    # excluding anything else (evolution, cheese, ...) filters nothing.
    environment.gnome.excludePackages = [
      pkgs.gnome-tour
      pkgs.epiphany
      pkgs.geary
      pkgs.gnome-music
      pkgs.gnome-contacts
    ];
  };
}
