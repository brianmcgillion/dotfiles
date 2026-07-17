#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Automated Hetzner Server Deployment Script
#
# This script automates the complete deployment process for Hetzner servers:
# 1. Loads NixOS kexec installer on the remote server
# 2. Extracts the SSH host key and converts it to age format
# 3. Updates SOPS configuration and re-encrypts secrets
# 4. Deploys the NixOS configuration using nixos-anywhere
#
# Usage:
#   ./deploy-hetzner-server.sh <hostname> [--skip-kexec]
#
# Examples:
#   ./deploy-hetzner-server.sh nubes
#   ./deploy-hetzner-server.sh nubes --skip-kexec
#   SSH_KEY=~/.ssh/my-key ./deploy-hetzner-server.sh nephele

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# Configuration
HOST="${1:?Usage: $0 <hostname> [--skip-kexec]}"
SKIP_KEXEC="${2:-}"
# Builder key, provisioned from sops by features.system.remote-builders.
SSH_KEY="${SSH_KEY:-/run/secrets/builder-key}"
# Overridable so a specific (pinned) release can be used; when KEXEC_SHA256
# is set the download is checksum-verified on the target before unpacking.
KEXEC_TARBALL="${KEXEC_TARBALL:-https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz}"
KEXEC_SHA256="${KEXEC_SHA256:-}"

# Banner
echo "======================================================================"
echo "         Automated Hetzner Server Deployment"
echo "======================================================================"
echo ""

# Validate SSH key exists
if [ ! -f "$SSH_KEY" ]; then
  log_error "SSH key not found: $SSH_KEY"
  log_info "Set SSH_KEY environment variable, or check that sops provisioned /run/secrets/builder-key"
  exit 1
fi

# Get host IP from configuration
get_host_ip() {
  local ip
  # Select the IPv4 entry explicitly (no ':') — the Address array's order
  # is not guaranteed, and some hosts define no 10-uplink network at all.
  ip=$(nix eval --json ".#nixosConfigurations.$HOST.config.systemd.network.networks.\"10-uplink\".networkConfig.Address" 2>&1 |
    grep -E '^\[' | jq -r '[.[] | select(test(":") | not)][0]' | cut -d'/' -f1 2>/dev/null)

  # Fallback: resolve the hostname via DNS/ssh-config for hosts without a
  # static 10-uplink Address array (e.g. DHCP cloud instances).
  if [ -z "$ip" ] || [ "$ip" == "null" ]; then
    ip=$(getent ahostsv4 "$HOST" 2>/dev/null | awk 'NR==1 {print $1}')
  fi

  if [ -z "$ip" ] || [ "$ip" == "null" ]; then
    log_error "Could not determine IP for host $HOST"
    log_info "Make sure the host configuration exists in flake.nix (or that \"$HOST\" resolves)"
    exit 1
  fi
  echo "$ip"
}

# Check if server is already in kexec installer
check_if_kexec() {
  if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
    root@"$1" "test -d /mnt-root" 2>/dev/null; then
    return 0 # Already in kexec
  fi
  return 1
}

# Wait for SSH to become available
wait_for_ssh() {
  local host="$1"
  local max_attempts="${2:-30}"

  log_info "Waiting for SSH to become available..."
  local attempt
  for attempt in $(seq 1 "$max_attempts"); do
    if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
      root@"$host" "echo 'Ready'" >/dev/null 2>&1; then
      log_info "SSH is ready!"
      return 0
    fi
    printf "."
    sleep 5
  done
  echo ""
  log_error "SSH did not become available after $attempt attempts"
  return 1
}

HOST_IP=$(get_host_ip)
log_info "Target: $HOST at $HOST_IP"
log_info "SSH Key: $SSH_KEY"
echo ""

# Step 0: Check if already in kexec installer
if [ "$SKIP_KEXEC" != "--skip-kexec" ]; then
  log_step "Checking if server is already in kexec installer..."
  if check_if_kexec "$HOST_IP"; then
    log_warn "Server appears to already be in kexec installer"
    read -p "Skip kexec step? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      SKIP_KEXEC="--skip-kexec"
      log_info "Skipping kexec step"
    fi
  fi
fi

# Step 1: Connect and load kexec installer (if not skipped)
if [ "$SKIP_KEXEC" != "--skip-kexec" ]; then
  log_step "Step 1: Loading NixOS kexec installer"
  log_info "Connecting to $HOST_IP..."

  if [ -n "$KEXEC_SHA256" ]; then
    KEXEC_CMD="curl -fL $KEXEC_TARBALL -o /root/kexec.tar.gz && echo '$KEXEC_SHA256  /root/kexec.tar.gz' | sha256sum -c - && tar -xzf /root/kexec.tar.gz -C /root && /root/kexec/run"
  else
    log_warn "KEXEC_SHA256 not set - kexec image will be executed unverified"
    KEXEC_CMD="curl -fL $KEXEC_TARBALL | tar -xzf- -C /root && /root/kexec/run"
  fi
  if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new root@"$HOST_IP" "$KEXEC_CMD"; then
    log_info "Kexec installer loaded successfully"
  else
    log_error "Failed to load kexec installer"
    exit 1
  fi

  # Wait for kexec to complete
  log_step "Step 2: Waiting for kexec to complete (60 seconds)"
  sleep 60

  # Wait for SSH to be available again
  if ! wait_for_ssh "$HOST_IP" 30; then
    log_error "Server did not come back online after kexec"
    exit 1
  fi
else
  log_info "Skipping kexec installer step (using existing installer)"
fi

echo ""

# Step 3: Get the new SSH host key and convert to age
log_step "Step 3: Extracting age key from SSH host key"
NEW_AGE_KEY=$(ssh-keyscan -H "$HOST_IP" 2>/dev/null | ssh-to-age | grep -v "skipped key" | head -1)

if [ -z "$NEW_AGE_KEY" ]; then
  log_error "Failed to extract age key from SSH host key"
  exit 1
fi

log_info "New age key: $NEW_AGE_KEY"
echo ""

# Step 4: Update .sops.yaml with new key
log_step "Step 4: Checking if SOPS key needs updating"

if ! grep -q "host_$HOST" .sops.yaml; then
  log_error "Host $HOST not found in .sops.yaml"
  log_info "Please add the host to .sops.yaml first"
  exit 1
fi

OLD_AGE_KEY=$(grep "host_$HOST" .sops.yaml | awk '{print $NF}')
log_info "Old age key: $OLD_AGE_KEY"

if [ "$OLD_AGE_KEY" != "$NEW_AGE_KEY" ]; then
  log_warn "Age key changed, updating .sops.yaml and secrets"

  # Backup .sops.yaml
  cp .sops.yaml .sops.yaml.backup
  log_info "Created backup: .sops.yaml.backup"

  # Files already re-encrypted this run; on failure they are rolled back
  # against the restored .sops.yaml so secrets and config stay consistent.
  UPDATED_FILES=()
  rollback_sops() {
    log_warn "Rolling back .sops.yaml and re-encrypting already-updated files"
    mv .sops.yaml.backup .sops.yaml
    local f
    for f in "${UPDATED_FILES[@]}"; do
      echo "y" | sops updatekeys "$f" >/dev/null 2>&1 ||
        log_error "Rollback failed for $f - fix manually before re-running"
    done
  }

  # Update .sops.yaml using a more robust approach
  # Using awk to avoid sed delimiter issues with long strings
  awk -v old="$OLD_AGE_KEY" -v new="$NEW_AGE_KEY" '{gsub(old,new)}1' .sops.yaml >.sops.yaml.tmp
  mv .sops.yaml.tmp .sops.yaml
  log_info "Updated .sops.yaml"

  echo ""
  log_step "Step 5: Updating SOPS secrets"

  # Update user secrets - auto-detect all user modules
  for user_dir in modules/users/*/; do
    if [ -d "$user_dir" ]; then
      # Find any .yaml files in the user directory (excluding default.nix)
      for secret_file in "$user_dir"*.yaml; do
        if [ -f "$secret_file" ]; then
          log_info "Updating $secret_file..."
          if echo "y" | sops updatekeys "$secret_file" 2>&1 | grep -q "synced with new keys"; then
            log_info "✓ $secret_file updated"
            UPDATED_FILES+=("$secret_file")
          else
            log_error "Failed to update $secret_file"
            rollback_sops
            exit 1
          fi
        fi
      done
    fi
  done

  # Update host-specific secrets
  if [ -f "hosts/$HOST/secrets.yaml" ]; then
    log_info "Updating hosts/$HOST/secrets.yaml..."
    if echo "y" | sops updatekeys "hosts/$HOST/secrets.yaml" 2>&1 | grep -q "synced with new keys"; then
      log_info "✓ hosts/$HOST/secrets.yaml updated"
      UPDATED_FILES+=("hosts/$HOST/secrets.yaml")
    else
      log_error "Failed to update hosts/$HOST/secrets.yaml"
      rollback_sops
      exit 1
    fi
  fi

  log_info "SOPS keys updated successfully"
  rm .sops.yaml.backup
else
  log_info "Age key unchanged, skipping SOPS update"
fi

echo ""

# Step 6: Verify configuration builds
log_step "Step 6: Verifying configuration builds"
if nix build ".#nixosConfigurations.$HOST.config.system.build.toplevel" --no-link 2>&1 | tail -3; then
  log_info "Configuration builds successfully"
else
  log_error "Configuration failed to build"
  exit 1
fi

echo ""

# Step 7: Deploy with nixos-anywhere
log_step "Step 7: Deploying with nixos-anywhere"
log_warn "This will wipe the disk and install NixOS"
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_info "Deployment cancelled"
  exit 0
fi

echo ""
log_info "Starting nixos-anywhere deployment..."
echo ""

# --copy-host-keys: Preserve SSH host keys from kexec installer
# This ensures SOPS can decrypt secrets on first boot with matching SSH keys
if nix run github:nix-community/nixos-anywhere -- \
  --flake ".#$HOST" \
  --copy-host-keys \
  --ssh-option "IdentityFile=$SSH_KEY" \
  "root@$HOST_IP"; then
  echo ""
  log_info "======================================================================"
  log_info "                  Deployment Complete!"
  log_info "======================================================================"
  log_info ""
  log_info "Server is rebooting. Wait 2-3 minutes then connect with:"
  log_info "  ssh -i $SSH_KEY root@$HOST_IP"
  log_info ""

  # Auto-detect primary user from configuration
  # shellcheck disable=SC2016
  PRIMARY_USER=$(nix eval --raw ".#nixosConfigurations.$HOST.config.users.users" --apply 'users: builtins.head (builtins.filter (u: users.${u}.isNormalUser or false) (builtins.attrNames users))' 2>/dev/null || echo "")

  if [ -n "$PRIMARY_USER" ]; then
    log_info "You can also login via Hetzner KVM console as user '$PRIMARY_USER'"
  else
    log_info "You can also login via Hetzner KVM console"
  fi
  log_info "======================================================================"
else
  log_error "Deployment failed"
  exit 1
fi
