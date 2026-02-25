#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Extract netrc credentials from SOPS-encrypted secrets.yaml
#
# Decrypts the 'netrc' key from secrets.yaml and writes it to ~/.netrc
# with secure permissions. Run this when setting up a new machine.
#
# Usage:
#   setup-netrc
#
# Requires: sops (available in nix develop)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SECRETS_FILE="${DOTFILES_DIR:-$HOME/.dotfiles}/secrets.yaml"
NETRC_FILE="$HOME/.netrc"

if [ ! -f "$SECRETS_FILE" ]; then
  log_error "Secrets file not found: $SECRETS_FILE"
  log_info "Set DOTFILES_DIR or ensure ~/.dotfiles/secrets.yaml exists"
  exit 1
fi

if ! command -v sops &>/dev/null; then
  log_error "'sops' not found. Run this from 'nix develop'."
  exit 1
fi

if [ -f "$NETRC_FILE" ]; then
  log_warn "$NETRC_FILE already exists"
  read -p "Overwrite? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted"
    exit 0
  fi
fi

log_info "Decrypting netrc from $SECRETS_FILE..."
if sops -d --extract '["netrc"]' "$SECRETS_FILE" >"$NETRC_FILE"; then
  chmod 600 "$NETRC_FILE"
  log_info "Written to $NETRC_FILE (mode 600)"
else
  log_error "Failed to decrypt netrc. Check your SOPS key access."
  rm -f "$NETRC_FILE"
  exit 1
fi
