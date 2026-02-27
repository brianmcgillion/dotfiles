# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# Nextcloud client configuration for Hetzner Storage Share
#
# Provides:
# - Nextcloud desktop client (GUI autostart via XDG .desktop file)
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
{ pkgs, ... }:
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
        ExecStart = pkgs.writeShellScript "nextcloud-sync" ''
          mkdir -p "$HOME/Documents/Papers" "$HOME/Documents/EPUB"
          mkdir -p "$HOME/Documents/org/remarkable"/{downloads,outbox,notes}

          # Sync academic papers
          ${pkgs.nextcloud-client}/bin/nextcloudcmd \
            -n --path "/Documents/Papers" --silent \
            "$HOME/Documents/Papers" \
            "https://nx89231.your-storageshare.de"

          # Sync ebooks
          ${pkgs.nextcloud-client}/bin/nextcloudcmd \
            -n --path "/Documents/EPUB" --silent \
            "$HOME/Documents/EPUB" \
            "https://nx89231.your-storageshare.de"

          # Sync reMarkable downloaded PDFs (with annotations pre-rendered)
          ${pkgs.nextcloud-client}/bin/nextcloudcmd \
            -n --path "/Documents/remarkable/downloads" --silent \
            "$HOME/Documents/org/remarkable/downloads" \
            "https://nx89231.your-storageshare.de"

          # Sync reMarkable handwritten notes (converted to PDF)
          ${pkgs.nextcloud-client}/bin/nextcloudcmd \
            -n --path "/Documents/remarkable/notes" --silent \
            "$HOME/Documents/org/remarkable/notes" \
            "https://nx89231.your-storageshare.de"
        '';
      };
    };

    # Timer for periodic sync (every 15 minutes)
    timers.nextcloud-sync = {
      Unit.Description = "Periodic Nextcloud Sync";
      Timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
