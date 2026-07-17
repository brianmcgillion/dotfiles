#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# (the shebang is for shellcheck/editors; writeShellApplication supplies the
# real interpreter line and set -euo pipefail when building the package)
# reMarkable sync script - USB Web Interface
#
# Requirements:
# - Enable USB web interface on device: Settings → Storage → USB web interface
# - Connect device via USB cable
#
# Usage:
#   remarkable-sync           # Full sync (down then up)
#   remarkable-sync down      # Download all PDFs with annotations
#   remarkable-sync up        # Upload outbox contents to device
#   remarkable-sync list      # List documents on device
#   remarkable-sync status    # Check device connectivity
#   remarkable-sync get UUID  # Download specific document

# Configuration
REMARKABLE_URL="${REMARKABLE_URL:-http://10.11.99.1}"
LOCAL_DIR="${REMARKABLE_DIR:-$HOME/Documents/org/remarkable}"
PAPERS_DIR="${PAPERS_DIR:-$HOME/Documents/Papers}"
EPUB_DIR="${EPUB_DIR:-$HOME/Documents/EPUB}"

# Directories (simplified - annotations are pre-rendered by device)
DOWNLOADS="$LOCAL_DIR/downloads"
OUTBOX="$LOCAL_DIR/outbox"
NOTES="$LOCAL_DIR/notes"
# Processed uploads live OUTSIDE the outbox so systemd path units watching
# the outbox are not re-triggered by the post-upload move.
PROCESSED="$LOCAL_DIR/.processed"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $*"; }

# Ensure directories exist
mkdir -p "$DOWNLOADS" "$OUTBOX" "$NOTES"

# Check if device is reachable via USB web interface
check_device() {
  if curl --silent --connect-timeout 3 "$REMARKABLE_URL/documents/" >/dev/null 2>&1; then
    log_info "reMarkable USB web interface is available"
    return 0
  else
    log_error "Cannot reach reMarkable at $REMARKABLE_URL"
    log_warn "Ensure:"
    log_warn "  1. Device is connected via USB"
    log_warn "  2. USB web interface is enabled (Settings → Storage)"
    log_warn "  3. Device is unlocked"
    return 1
  fi
}

# Get document list as JSON
get_documents() {
  local parent="${1:-}"
  local url="$REMARKABLE_URL/documents/$parent"
  curl --silent --connect-timeout 5 --max-time 30 "$url"
}

# List all documents (recursive)
list_documents() {
  log_info "Listing documents on device..."
  check_device || return 1

  echo ""
  echo "Documents on reMarkable:"
  echo "========================"

  # Get root documents
  get_documents | jq -r '.[] | "\(.Type)\t\(.ID)\t\(.VissibleName)"' | while IFS=$'\t' read -r type id name; do
    if [ "$type" = "CollectionType" ]; then
      echo -e "📁 $name/"
      # List folder contents (one level)
      get_documents "$id" | jq -r '.[] | "   \(.Type)\t\(.ID)\t\(.VissibleName)"' 2>/dev/null | while IFS=$'\t' read -r subtype subid subname; do
        if [ "$subtype" = "CollectionType" ]; then
          echo "   📁 $subname/"
        else
          echo "   📄 $subname  [$subid]"
        fi
      done
    else
      echo -e "📄 $name  [$id]"
    fi
  done
}

# Download a specific document by UUID
download_document() {
  local uuid="$1"
  local output_dir="${2:-$DOWNLOADS}"
  local name

  # Get document metadata to find name
  name=$(curl --silent "$REMARKABLE_URL/documents/" | jq -r ".[] | select(.ID == \"$uuid\") | .VissibleName" 2>/dev/null)

  if [ -z "$name" ]; then
    # Try searching in subfolders
    name=$(curl --silent "$REMARKABLE_URL/documents/" | jq -r '.[].ID' | while read -r folder_id; do
      curl --silent "$REMARKABLE_URL/documents/$folder_id" 2>/dev/null | jq -r ".[] | select(.ID == \"$uuid\") | .VissibleName"
    done | head -1)
  fi

  if [ -z "$name" ]; then
    name="$uuid"
  fi

  local output_file="$output_dir/$name.pdf"
  log_info "Downloading: $name → $output_file"

  if ! curl --silent --fail --connect-timeout 5 --max-time 120 -o "$output_file" "$REMARKABLE_URL/download/$uuid/pdf"; then
    log_error "Failed to download $uuid"
    return 1
  fi

  log_info "Downloaded: $output_file"
}

# Download all documents (with annotations rendered)
sync_down() {
  log_info "Downloading documents from reMarkable..."
  check_device || return 1

  # Process root level
  get_documents | jq -r '.[] | "\(.Type)\t\(.ID)\t\(.VissibleName)"' | while IFS=$'\t' read -r type id name; do
    if [ "$type" = "CollectionType" ]; then
      # Create folder locally
      mkdir -p "$DOWNLOADS/$name"

      # Download folder contents
      get_documents "$id" | jq -r '.[] | select(.Type == "DocumentType") | "\(.ID)\t\(.VissibleName)"' | while IFS=$'\t' read -r doc_id doc_name; do
        local output_file="$DOWNLOADS/$name/$doc_name.pdf"
        if [ ! -f "$output_file" ]; then
          log_info "Downloading: $name/$doc_name"
          curl --silent --fail --connect-timeout 5 --max-time 120 -o "$output_file" "$REMARKABLE_URL/download/$doc_id/pdf" 2>/dev/null ||
            log_warn "Failed to download $doc_name"
        fi
      done
    else
      # Root level document
      local output_file="$DOWNLOADS/$name.pdf"
      if [ ! -f "$output_file" ]; then
        log_info "Downloading: $name"
        curl --silent --fail --connect-timeout 5 --max-time 120 -o "$output_file" "$REMARKABLE_URL/download/$id/pdf" 2>/dev/null ||
          log_warn "Failed to download $name"
      fi
    fi
  done

  log_info "Download complete. Files saved to $DOWNLOADS"
}

# Upload files from outbox to device
sync_up() {
  log_info "Uploading files to reMarkable..."
  check_device || return 1

  # First, list root to set upload destination
  curl --silent "$REMARKABLE_URL/documents/" >/dev/null

  # Check if outbox has files
  shopt -s nullglob
  local files=("$OUTBOX"/*.{pdf,epub,PDF,EPUB})
  shopt -u nullglob

  if [ ${#files[@]} -eq 0 ]; then
    log_warn "Outbox is empty, nothing to upload"
    return 0
  fi

  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    local filename
    filename=$(basename "$file")
    log_info "Uploading: $filename"

    # Determine content type
    local content_type="application/pdf"
    if [[ $filename =~ \.[eE][pP][uU][bB]$ ]]; then
      content_type="application/epub+zip"
    fi

    if curl --silent --fail \
      -H "Origin: $REMARKABLE_URL" \
      -H "Accept: */*" \
      -H "Referer: $REMARKABLE_URL/" \
      -H "Connection: keep-alive" \
      -F "file=@$file;filename=$filename;type=$content_type" \
      "$REMARKABLE_URL/upload" >/dev/null; then

      # Move to processed folder (outside the watched outbox)
      mkdir -p "$PROCESSED"
      mv "$file" "$PROCESSED/"
      log_info "Uploaded: $filename"
    else
      log_error "Failed to upload: $filename"
    fi
  done

  log_info "Upload complete"
}

# Show status
show_status() {
  echo "=== reMarkable Sync Status ==="
  echo ""
  echo "Configuration:"
  echo "  URL:        $REMARKABLE_URL"
  echo "  Local dir:  $LOCAL_DIR"
  echo "  Papers:     $PAPERS_DIR"
  echo "  EPUB:       $EPUB_DIR"
  echo ""
  echo "Directories:"
  echo "  Downloads:  $(find "$DOWNLOADS" -type f -name '*.pdf' 2>/dev/null | wc -l) PDFs"
  echo "  Outbox:     $(find "$OUTBOX" -maxdepth 1 -type f 2>/dev/null | wc -l) files pending"
  echo "  Notes:      $(find "$NOTES" -type f 2>/dev/null | wc -l) files"
  echo ""

  if check_device 2>/dev/null; then
    echo "Device: Connected via USB"
    local doc_count
    doc_count=$(get_documents | jq 'length' 2>/dev/null || echo "?")
    echo "Documents on device: $doc_count (root level)"
  else
    echo "Device: Not connected"
  fi
}

# Main command handler
case "${1:-sync}" in
down | pull | download)
  sync_down
  ;;
up | push | upload)
  sync_up
  ;;
list | ls)
  list_documents
  ;;
get)
  if [ -z "${2:-}" ]; then
    log_error "Usage: remarkable-sync get <UUID> [output_dir]"
    exit 1
  fi
  check_device || exit 1
  download_document "$2" "${3:-$DOWNLOADS}"
  ;;
status)
  show_status
  ;;
sync | "")
  sync_down
  sync_up
  ;;
help | --help | -h)
  echo "remarkable-sync - USB Web Interface sync tool"
  echo ""
  echo "Usage: remarkable-sync [command]"
  echo ""
  echo "Commands:"
  echo "  down, pull    Download all PDFs (with annotations) from device"
  echo "  up, push      Upload outbox contents to device"
  echo "  list, ls      List documents on device"
  echo "  get <UUID>    Download specific document by UUID"
  echo "  status        Show sync status and connectivity"
  echo "  sync          Full sync (default): down + up"
  echo "  help          Show this help"
  echo ""
  echo "Environment variables:"
  echo "  REMARKABLE_URL   Device URL (default: http://10.11.99.1)"
  echo "  REMARKABLE_DIR   Local sync directory"
  echo ""
  echo "Setup:"
  echo "  1. On reMarkable: Settings → Storage → Enable 'USB web interface'"
  echo "  2. Connect device via USB cable"
  echo "  3. Run: remarkable-sync status"
  ;;
*)
  log_error "Unknown command: $1"
  echo "Run 'remarkable-sync help' for usage"
  exit 1
  ;;
esac
