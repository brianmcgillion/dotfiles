#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025-2026 Brian McGillion
#
# Nebula Add Device Script
#
# Generates a portable bundle for adding non-NixOS devices to the Nebula
# "pantheon" network. The bundle contains certificates, a ready-to-use
# config, and an install script for Ubuntu/Debian targets.
#
# Usage:
#   ./scripts/nebula-add-device.sh <hostname> <nebula-ip>
#
# Examples:
#   ./scripts/nebula-add-device.sh ubuntu-dev 10.99.99.10
#   ./scripts/nebula-add-device.sh pi-sensor 10.99.99.20
#
# Then copy to target and run:
#   scp -r nebula-<hostname>/ user@target:~/
#   ssh user@target 'sudo ~/nebula-<hostname>/install.sh'
#
# Requirements (available in nix develop):
#   - sops
#   - nebula-cert (from nebula package)

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

# --- Arguments ---
HOSTNAME="${1:?Usage: $0 <hostname> <nebula-ip>}"
NEBULA_IP="${2:?Usage: $0 <hostname> <nebula-ip>}"

# --- Network configuration (must match nebula.nix) ---
LIGHTHOUSE_NEBULA_IP="10.99.99.1"
LIGHTHOUSE_PUBLIC_IP="95.217.167.39"
LISTEN_PORT="4242"
DNS_DOMAIN="pantheon.bmg.sh"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="nebula-${HOSTNAME}"

# Temp directory for CA key (cleaned up on exit)
TMPDIR_CA=""
cleanup() {
  if [ -n "$TMPDIR_CA" ] && [ -d "$TMPDIR_CA" ]; then
    rm -rf "$TMPDIR_CA"
    log_info "Cleaned up temporary CA credentials"
  fi
}
trap cleanup EXIT

# Banner
echo "======================================================================"
echo "         Nebula Add Device — pantheon network"
echo "======================================================================"
echo ""
log_info "Hostname:  ${HOSTNAME}"
log_info "Nebula IP: ${NEBULA_IP}"
echo ""

# --- Validate tools ---
for cmd in sops nebula-cert; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "'$cmd' not found. Run 'nix develop' first."
    exit 1
  fi
done

# --- Validate IP format ---
if ! [[ $NEBULA_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_error "Invalid Nebula IP: $NEBULA_IP"
  exit 1
fi

# --- Step 1: Extract CA credentials from SOPS ---
log_step "Extracting CA credentials from SOPS..."

TMPDIR_CA="$(mktemp -d)"

sops --extract '["ca"]' -d "$REPO_DIR/secrets.yaml" >"$TMPDIR_CA/ca.key"
sops --extract '["ca-cert"]' -d "$REPO_DIR/secrets.yaml" >"$TMPDIR_CA/ca.crt"

chmod 600 "$TMPDIR_CA/ca.key"
log_info "CA credentials extracted"

# --- Step 2: Generate node certificate ---
log_step "Generating certificate for ${HOSTNAME} (${NEBULA_IP}/16)..."

mkdir -p "$OUTPUT_DIR"

nebula-cert sign \
  -ca-crt "$TMPDIR_CA/ca.crt" \
  -ca-key "$TMPDIR_CA/ca.key" \
  -name "$HOSTNAME" \
  -ip "${NEBULA_IP}/16" \
  -out-crt "$OUTPUT_DIR/${HOSTNAME}.crt" \
  -out-key "$OUTPUT_DIR/${HOSTNAME}.key"

# Copy CA cert (public only) to output
cp "$TMPDIR_CA/ca.crt" "$OUTPUT_DIR/ca.crt"

log_info "Certificates generated"

# --- Step 3: Generate config.yml ---
log_step "Generating config.yml..."

cat >"$OUTPUT_DIR/config.yml" <<EOF
pki:
  ca: /etc/nebula/ca.crt
  cert: /etc/nebula/${HOSTNAME}.crt
  key: /etc/nebula/${HOSTNAME}.key

static_host_map:
  "${LIGHTHOUSE_NEBULA_IP}":
    - "${LIGHTHOUSE_PUBLIC_IP}:${LISTEN_PORT}"

lighthouse:
  am_lighthouse: false
  hosts:
    - "${LIGHTHOUSE_NEBULA_IP}"

listen:
  host: 0.0.0.0
  port: ${LISTEN_PORT}

punchy:
  punch: true
  respond: true

relay:
  am_relay: false
  relays:
    - "${LIGHTHOUSE_NEBULA_IP}"
  use_relays: true

tun:
  dev: nebula-pantheon

firewall:
  outbound:
    - port: any
      proto: any
      host: any

  inbound:
    - port: any
      proto: icmp
      host: any

    - port: 22
      proto: tcp
      host: any
EOF

log_info "config.yml generated"

# --- Step 4: Generate install.sh ---
log_step "Generating install.sh..."

cat >"$OUTPUT_DIR/install.sh" <<'INSTALL_HEADER'
#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025-2026 Brian McGillion
#
# Nebula install script for Ubuntu/Debian targets
# Run as root: sudo ./install.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
  log_error "This script must be run as root (use sudo)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_HEADER

# Inject the hostname variable (not single-quoted, so it expands)
cat >>"$OUTPUT_DIR/install.sh" <<INSTALL_VARS
HOSTNAME="${HOSTNAME}"
DNS_DOMAIN="${DNS_DOMAIN}"
LIGHTHOUSE_IP="${LIGHTHOUSE_NEBULA_IP}"
INSTALL_VARS

cat >>"$OUTPUT_DIR/install.sh" <<'INSTALL_BODY'

# --- Install Nebula ---
log_info "Installing Nebula..."

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  NEBULA_ARCH="linux-amd64" ;;
  aarch64) NEBULA_ARCH="linux-arm64" ;;
  armv7l)  NEBULA_ARCH="linux-arm-7" ;;
  *)
    log_error "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

NEBULA_VERSION="$(curl -fsSL https://api.github.com/repos/slackhq/nebula/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')"
NEBULA_URL="https://github.com/slackhq/nebula/releases/download/v${NEBULA_VERSION}/nebula-${NEBULA_ARCH}.tar.gz"

log_info "Downloading Nebula v${NEBULA_VERSION} for ${NEBULA_ARCH}..."
curl -fsSL "$NEBULA_URL" -o /tmp/nebula.tar.gz
tar -xzf /tmp/nebula.tar.gz -C /usr/local/bin nebula nebula-cert
chmod 755 /usr/local/bin/nebula /usr/local/bin/nebula-cert
rm -f /tmp/nebula.tar.gz

log_info "Nebula v${NEBULA_VERSION} installed to /usr/local/bin/"

# --- Copy configuration ---
log_info "Installing configuration to /etc/nebula/..."

mkdir -p /etc/nebula
cp "$SCRIPT_DIR/ca.crt" /etc/nebula/ca.crt
cp "$SCRIPT_DIR/${HOSTNAME}.crt" /etc/nebula/${HOSTNAME}.crt
cp "$SCRIPT_DIR/${HOSTNAME}.key" /etc/nebula/${HOSTNAME}.key
cp "$SCRIPT_DIR/config.yml" /etc/nebula/config.yml

chmod 600 /etc/nebula/${HOSTNAME}.key
chmod 644 /etc/nebula/ca.crt /etc/nebula/${HOSTNAME}.crt /etc/nebula/config.yml

# --- Create systemd service ---
log_info "Creating systemd service..."

cat > /etc/systemd/system/nebula.service << UNIT
[Unit]
Description=Nebula Overlay Network
Wants=basic.target network-online.target
After=basic.target network.target network-online.target
Before=sshd.service

[Service]
Type=simple
ExecStart=/usr/local/bin/nebula -config /etc/nebula/config.yml
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

# --- Enable and start ---
systemctl daemon-reload
systemctl enable nebula.service
systemctl restart nebula.service

log_info "Nebula service enabled and started"

# --- Configure DNS resolution ---
log_info "Configuring DNS for ${DNS_DOMAIN}..."

# Wait briefly for the interface to come up
sleep 2

if command -v resolvectl &>/dev/null; then
  # Find the nebula interface name
  NEBULA_IF="$(ip -o link show | grep -o 'nebula-[^ :@]*' | head -1)" || true
  if [ -n "$NEBULA_IF" ]; then
    resolvectl dns "$NEBULA_IF" "$LIGHTHOUSE_IP"
    resolvectl domain "$NEBULA_IF" "$DNS_DOMAIN"
    log_info "DNS configured: ${DNS_DOMAIN} → ${LIGHTHOUSE_IP} on ${NEBULA_IF}"
  else
    log_info "Nebula interface not yet available — DNS will be configured on next restart"
    # Create a drop-in to configure DNS on service start
    mkdir -p /etc/systemd/system/nebula.service.d
    cat > /etc/systemd/system/nebula.service.d/dns.conf << DROPIN
[Service]
ExecStartPost=/bin/bash -c 'sleep 2 && resolvectl dns nebula-pantheon ${LIGHTHOUSE_IP} && resolvectl domain nebula-pantheon ${DNS_DOMAIN}'
DROPIN
    systemctl daemon-reload
  fi
else
  log_info "resolvectl not found — skipping DNS configuration"
  log_info "You may need to manually configure DNS for ${DNS_DOMAIN}"
fi

# --- Verify ---
log_info "Verifying..."
if systemctl is-active --quiet nebula.service; then
  log_info "Nebula service is running"
else
  log_error "Nebula service failed to start. Check: journalctl -u nebula.service"
  exit 1
fi

echo ""
log_info "Installation complete!"
log_info "Test connectivity: ping ${LIGHTHOUSE_IP}"
INSTALL_BODY

chmod +x "$OUTPUT_DIR/install.sh"
log_info "install.sh generated"

# --- Done ---
echo ""
echo "======================================================================"
log_info "Bundle ready: ${OUTPUT_DIR}/"
echo "======================================================================"
echo ""
log_info "Contents:"
ls -la "$OUTPUT_DIR/"
echo ""
log_info "Next steps:"
log_info "  scp -r ${OUTPUT_DIR}/ user@target:~/"
log_info "  ssh user@target 'sudo ~/${OUTPUT_DIR}/install.sh'"
