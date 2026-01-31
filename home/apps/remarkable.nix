# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# reMarkable Home Manager configuration
#
# Uses USB Web Interface (http://10.11.99.1) - NO developer mode required!
#
# Provides systemd user services for automatic sync:
# - Path watcher: triggers upload when files added to outbox
# - Timer (optional): periodic check for device connection
#
# Usage in home configuration:
#   imports = [ ./apps/remarkable.nix ];
#
# Manual trigger:
#   systemctl --user start remarkable-sync.service
#
# Check status:
#   systemctl --user status remarkable-outbox.path
#   journalctl --user -u remarkable-sync.service
{
  config,
  pkgs,
  ...
}:
let
  remarkableDir = "${config.home.homeDirectory}/Documents/org/remarkable";
  remarkableUrl = "http://10.11.99.1";
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
        ExecStart = "${pkgs.writeShellScript "remarkable-upload" ''
          set -euo pipefail
          OUTBOX="${remarkableDir}/outbox"
          LOGFILE="${remarkableDir}/.sync.log"
          REMARKABLE_URL="${remarkableUrl}"

          log() { echo "[$(date -Iseconds)] $*" >> "$LOGFILE"; }

          log "Upload triggered"

          # Check if device is reachable
          if ! ${pkgs.curl}/bin/curl --silent --connect-timeout 3 "$REMARKABLE_URL/documents/" >/dev/null 2>&1; then
            log "Device not connected via USB, skipping"
            exit 0
          fi

          # Check if outbox has files
          shopt -s nullglob
          files=("$OUTBOX"/*.{pdf,epub,PDF,EPUB})
          if [ ''${#files[@]} -eq 0 ]; then
            log "Outbox empty, skipping"
            exit 0
          fi

          # List root to set upload destination
          ${pkgs.curl}/bin/curl --silent "$REMARKABLE_URL/documents/" >/dev/null

          # Upload each file
          for file in "''${files[@]}"; do
            filename=$(basename "$file")
            log "Uploading: $filename"

            # Determine content type
            content_type="application/pdf"
            if [[ "$filename" =~ \.[eE][pP][uU][bB]$ ]]; then
              content_type="application/epub+zip"
            fi

            if ${pkgs.curl}/bin/curl --silent --fail \
              -H "Origin: $REMARKABLE_URL" \
              -H "Accept: */*" \
              -H "Referer: $REMARKABLE_URL/" \
              -F "file=@$file;filename=$filename;type=$content_type" \
              "$REMARKABLE_URL/upload" >/dev/null 2>> "$LOGFILE"; then
              mkdir -p "$OUTBOX/.processed"
              mv "$file" "$OUTBOX/.processed/"
              log "Success: $filename"
            else
              log "Failed: $filename"
            fi
          done
        ''}";
        Environment = [
          "HOME=${config.home.homeDirectory}"
        ];
      };
    };

    # Full sync service - downloads from device (uses USB web interface)
    services.remarkable-sync = {
      Unit = {
        Description = "Full reMarkable sync via USB web interface";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "remarkable-full-sync" ''
          set -euo pipefail
          LOCAL_DIR="${remarkableDir}"
          REMARKABLE_URL="${remarkableUrl}"
          LOGFILE="$LOCAL_DIR/.sync.log"
          DOWNLOADS="$LOCAL_DIR/downloads"
          OUTBOX="$LOCAL_DIR/outbox"

          log() { echo "[$(date -Iseconds)] $*" >> "$LOGFILE"; }

          mkdir -p "$DOWNLOADS" "$OUTBOX"

          log "Full sync started"

          # Check device connectivity (with proper timeout for slow web interface)
          if ! ${pkgs.curl}/bin/curl --silent --connect-timeout 3 --max-time 15 "$REMARKABLE_URL/documents/" >/dev/null 2>&1; then
            log "Device not connected or web interface not responding, skipping"
            exit 0
          fi

          log "Downloading documents..."

          # Get root documents and download PDFs (with timeouts to prevent hanging)
          ${pkgs.curl}/bin/curl --silent --connect-timeout 5 --max-time 30 "$REMARKABLE_URL/documents/" | \
            ${pkgs.jq}/bin/jq -r '.[] | "\(.Type)\t\(.ID)\t\(.VissibleName)"' | \
            while IFS=$'\t' read -r type id name; do
              if [ "$type" = "DocumentType" ]; then
                output_file="$DOWNLOADS/$name.pdf"
                if [ ! -f "$output_file" ]; then
                  log "Downloading: $name"
                  ${pkgs.curl}/bin/curl --silent --fail --connect-timeout 5 --max-time 120 -o "$output_file" \
                    "$REMARKABLE_URL/download/$id/pdf" 2>/dev/null || log "Failed: $name"
                fi
              elif [ "$type" = "CollectionType" ]; then
                # Download folder contents
                mkdir -p "$DOWNLOADS/$name"
                ${pkgs.curl}/bin/curl --silent --connect-timeout 5 --max-time 30 "$REMARKABLE_URL/documents/$id" | \
                  ${pkgs.jq}/bin/jq -r '.[] | select(.Type == "DocumentType") | "\(.ID)\t\(.VissibleName)"' | \
                  while IFS=$'\t' read -r doc_id doc_name; do
                    output_file="$DOWNLOADS/$name/$doc_name.pdf"
                    if [ ! -f "$output_file" ]; then
                      log "Downloading: $name/$doc_name"
                      ${pkgs.curl}/bin/curl --silent --fail --connect-timeout 5 --max-time 120 -o "$output_file" \
                        "$REMARKABLE_URL/download/$doc_id/pdf" 2>/dev/null || log "Failed: $doc_name"
                    fi
                  done
              fi
            done

          log "Full sync complete"
        ''}";
        Environment = [
          "HOME=${config.home.homeDirectory}"
        ];
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
