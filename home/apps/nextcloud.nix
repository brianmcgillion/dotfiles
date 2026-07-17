# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# Nextcloud client configuration for Hetzner Storage Share
#
# Provides:
# - Nextcloud desktop client (launch the GUI manually when needed)
# - Systemd timer for periodic CLI sync (every 15 minutes)
#
# Synced directories:
# - ~/Documents/Papers                    <-> /Documents/Papers (academic PDFs)
# - ~/Documents/EPUB                      <-> /Documents/EPUB (ebooks)
# - ~/Documents/org/remarkable/downloads  <-> /Documents/remarkable/downloads (PDFs with annotations)
# - ~/Documents/org/remarkable/notes      <-> /Documents/remarkable/notes (handwritten notes as PDF)
#
# NOT synced (local only):
# - ~/Documents/org/remarkable/outbox (temporary staging for upload)
#
# Authentication:
# - Uses ~/.netrc for credentials (machine nx89231.your-storageshare.de)
#
# Manual setup required:
# 1. Add credentials to ~/.netrc:
#    machine nx89231.your-storageshare.de login USERNAME password APP_PASSWORD
# 2. Create remote folders in Nextcloud web UI if they don't exist
# 3. (Optional) Launch nextcloud GUI for interactive sync management
#
# Server: https://nx89231.your-storageshare.de
{ pkgs, lib, ... }:
let
  # Wrap nextcloud-client with GTK schemas to fix file chooser crash
  nextcloud-client-wrapped = pkgs.symlinkJoin {
    name = "nextcloud-client-wrapped";
    paths = [ pkgs.nextcloud-client ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nextcloud \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    '';
  };

  serverUrl = "https://nx89231.your-storageshare.de";

  # local dir (relative to $HOME) -> remote folder
  syncPairs = {
    "Documents/Papers" = "/Documents/Papers";
    "Documents/EPUB" = "/Documents/EPUB";
    "Documents/org/remarkable/downloads" = "/Documents/remarkable/downloads";
    "Documents/org/remarkable/notes" = "/Documents/remarkable/notes";
  };

  # Every pair is attempted; the unit fails (visible in systemctl status)
  # if any single sync failed.
  syncScript = pkgs.writeShellScript "nextcloud-sync" ''
    set -u
    rc=0
    mkdir -p "$HOME/Documents/org/remarkable"/{downloads,outbox,notes}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (local: remote: ''
        mkdir -p "$HOME/${local}"
        ${pkgs.nextcloud-client}/bin/nextcloudcmd \
          -n --path "${remote}" --silent \
          "$HOME/${local}" \
          "${serverUrl}" || { echo "sync failed: ${local}" >&2; rc=1; }
      '') syncPairs
    )}
    exit $rc
  '';
in
{
  home.packages = [ nextcloud-client-wrapped ];

  systemd.user = {
    services.nextcloud-sync = {
      Unit = {
        Description = "Nextcloud CLI Sync";
      };
      Service = {
        Type = "oneshot";
        ExecStart = syncScript;
      };
    };

    # Timer for periodic sync (every 15 minutes).
    # No Persistent=: it only applies to OnCalendar= timers.
    timers.nextcloud-sync = {
      Unit.Description = "Periodic Nextcloud Sync";
      Timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
