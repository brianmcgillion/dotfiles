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
# Caveat: logind's idle timer only watches session input activity (keyboard,
# mouse, tty), never CPU or GPU load. A local build pinning every core is
# still "idle" and will be suspended out from under itself. Hosts that must
# never auto-suspend should set idleAction = "ignore".
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

    idleAction = lib.mkOption {
      type = lib.types.enum [
        "ignore"
        "suspend"
        "hibernate"
        "hybrid-sleep"
        "suspend-then-hibernate"
        "sleep"
        "lock"
        "poweroff"
      ];
      default = "suspend";
      description = ''
        Action logind takes once every session is idle. Set to "ignore" on hosts
        that must never auto-suspend (e.g. build/ML machines) — logind's idle
        timer only watches input activity, not CPU or GPU load, so a busy
        unattended build still counts as idle.
      '';
    };

    idleActionSec = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "Time after all sessions are idle before logind triggers suspend.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable GNOME's auto-suspend — logind handles this instead.
    # The keys are locked: without locks the user dconf database wins, so
    # ever touching GNOME's power settings would silently re-enable the
    # SSH-killing auto-suspend this module exists to prevent.
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
        locks = [
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type"
        ];
      }
    ];

    # Let logind handle suspend — it sees all sessions including SSH
    services.logind.settings.Login = {
      IdleAction = cfg.idleAction;
      IdleActionSec = cfg.idleActionSec;
    };

    # Enable Wake-on-LAN for ethernet interfaces so the machine can be
    # woken by incoming network traffic (e.g. Nebula UDP probes on the
    # physical NIC). This allows remote SSH-over-Nebula to wake a
    # suspended machine automatically.
    # Note: Has no effect on WiFi-only devices (e.g. laptops).
    systemd.network.links."50-wol" = {
      matchConfig.Type = "ether";
      linkConfig.WakeOnLan = "unicast";
    };
  };
}
