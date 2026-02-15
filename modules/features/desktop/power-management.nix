# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# SSH-aware power management for GNOME desktops
#
# GNOME's power daemon only monitors the local graphical session and will
# auto-suspend even when SSH users are connected, killing remote sessions
# and any running workloads.
#
# This module:
# 1. Disables GNOME's built-in auto-suspend via dconf system defaults
# 2. Delegates suspend to systemd-logind, which tracks ALL sessions
#    (local + SSH). SSH sessions have IdleHint=no for their lifetime,
#    so logind's IdleAction will never trigger while someone is SSH'd in.
#
# Note: Screen blanking (idle-delay) is intentionally not touched — it is
# independent of suspend and remains under GNOME's control.
#
# Caveat: If an SSH session disconnects, the logind session ends even if
# tmux/screen processes persist. Long-running jobs should use
# systemd-inhibit or systemd-run --scope for protection.
#
# Usage:
#   features.desktop.power-management.enable = true;
#
# Enabled by default in: profile-client
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.desktop.power-management;
in
{
  options.features.desktop.power-management = {
    enable = lib.mkEnableOption "SSH-aware power management for GNOME desktops";

    idleActionSec = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "Time after all sessions are idle before logind triggers suspend.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable GNOME's auto-suspend — logind handles this instead
    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-timeout = lib.gvariant.mkUint32 0;
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-timeout = lib.gvariant.mkUint32 0;
            sleep-inactive-battery-type = "nothing";
          };
        };
      }
    ];

    # Let logind handle suspend — it sees all sessions including SSH
    services.logind.settings.Login = {
      IdleAction = "suspend";
      IdleActionSec = cfg.idleActionSec;
    };
  };
}
