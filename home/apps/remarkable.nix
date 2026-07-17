# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# reMarkable Home Manager automation
#
# Uses USB Web Interface (http://10.11.99.1) - NO developer mode required!
#
# The sync logic itself lives in the shared pkgs.remarkable-sync CLI
# (packages/remarkable-sync/); this module only provides the systemd user
# units that automate it:
# - Path watcher: triggers upload when files are added to the outbox
# - Timer (optional): periodic download of annotated documents
#
# Device-not-connected is a clean skip (exit 0), so the units stay green
# when the tablet is unplugged. Logs go to the journal:
#   journalctl --user -u remarkable-sync.service
#
# Manual trigger:
#   systemctl --user start remarkable-sync.service
#
# Check status:
#   systemctl --user status remarkable-outbox.path
{
  config,
  pkgs,
  ...
}:
let
  remarkableDir = "${config.home.homeDirectory}/Documents/org/remarkable";
  remarkableUrl = "http://10.11.99.1";

  # Run a remarkable-sync subcommand, but skip quietly when the device is
  # not connected — automation must not fail the unit on an unplugged
  # tablet, while the interactive CLI should keep reporting the error.
  syncWhenConnected = pkgs.writeShellApplication {
    name = "remarkable-sync-when-connected";
    runtimeInputs = [
      pkgs.curl
      pkgs.remarkable-sync
    ];
    text = ''
      if ! curl --silent --connect-timeout 3 --max-time 15 "${remarkableUrl}/documents/" >/dev/null 2>&1; then
        echo "reMarkable not connected, skipping"
        exit 0
      fi
      exec remarkable-sync "$@"
    '';
  };
in
{
  # Ensure directories exist
  home.file."Documents/org/remarkable/.keep".text = "";

  # systemd user services for reMarkable sync
  systemd.user = {
    # Path watcher - triggers upload when files added to outbox
    paths.remarkable-outbox = {
      Unit = {
        Description = "Watch reMarkable outbox for new files";
        Documentation = "man:systemd.path(5)";
      };
      Path = {
        PathChanged = "${remarkableDir}/outbox";
        Unit = "remarkable-sync-up.service";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Upload service - triggered by path watcher (uses USB web interface)
    services.remarkable-sync-up = {
      Unit = {
        Description = "Upload files to reMarkable via USB web interface";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${syncWhenConnected}/bin/remarkable-sync-when-connected up";
      };
    };

    # Download service - fetches annotated documents from the device
    services.remarkable-sync = {
      Unit = {
        Description = "Download reMarkable documents via USB web interface";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${syncWhenConnected}/bin/remarkable-sync-when-connected down";
      };
    };

    # Optional timer for periodic sync check (disabled by default)
    # Enable with: systemctl --user enable --now remarkable-sync.timer
    timers.remarkable-sync = {
      Unit = {
        Description = "Periodic reMarkable sync (when USB connected)";
      };
      Timer = {
        OnCalendar = "*:0/15"; # Every 15 minutes
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
