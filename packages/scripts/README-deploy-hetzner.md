<!--
SPDX-License-Identifier: MIT
SPDX-FileCopyrightText: 2025 Brian McGillion
-->

# Automated Hetzner Server Deployment

## Overview

The `deploy-hetzner-server` script automates the complete deployment process for Hetzner dedicated servers, handling:

1. Loading NixOS kexec installer on the remote server
2. Extracting SSH host keys and converting to age format
3. Updating SOPS configuration and re-encrypting secrets with new keys
4. Deploying with nixos-anywhere (includes --copy-host-keys for SOPS compatibility)
5. Server reboots into fully configured NixOS system

## Quick Start

### From Development Shell (Recommended)

Enter the development shell and use the command directly:

```bash
# Enter devshell
nix develop

# Deploy a server
deploy-hetzner-server nubes
deploy-hetzner-server caelus
```

### Direct Script Execution

```bash
# From repository root
./packages/scripts/deploy-hetzner-server.sh <hostname>

# With custom SSH key
SSH_KEY=~/.ssh/builder-key ./packages/scripts/deploy-hetzner-server.sh <hostname>

# Skip kexec (if already in installer)
./packages/scripts/deploy-hetzner-server.sh <hostname> --skip-kexec
```

## Available Servers

| Server | Type | Purpose |
|--------|------|---------|
| **nubes** | Hetzner Dedicated | Production server |
| **caelus** | Hetzner Cloud | Nebula lighthouse |

## Usage Examples

### Fresh Deployment (Complete Process)

```bash
# Enter devshell
nix develop

# Deploy nubes from scratch (full automated process)
deploy-hetzner-server nubes
```

This will:
1. Load kexec installer on the server
2. Extract SSH host key → Convert to age key
3. Update `.sops.yaml` with new age key
4. Re-encrypt all secrets with updated keys
5. Deploy NixOS with nixos-anywhere (--copy-host-keys)
6. Reboot into new system

### Redeploy (Server Already in Kexec)

If the server is already running the kexec installer:

```bash
deploy-hetzner-server nubes --skip-kexec
```

### Custom SSH Key

Default: `~/.ssh/builder-key`

To use a different key:

```bash
SSH_KEY=~/.ssh/my-key deploy-hetzner-server nubes
```

## Requirements

All requirements are automatically available in the development shell:

```bash
nix develop  # Provides all tools below
```

Required tools (provided by devshell):
- ✅ `nix` with flakes enabled
- ✅ `jq` for JSON parsing
- ✅ `ssh-to-age` for SSH key → age key conversion
- ✅ `sops` for secrets management
- ✅ SSH access to target server

Additional requirements:
- SSH key file (default: `~/.ssh/builder-key`)
- Host configuration in `hosts/<hostname>/`
- Host SOPS rules in `.sops.yaml`

## Process Flow

The script performs these steps automatically:

### 1. **Pre-flight Checks**
- Validates hostname is provided
- Checks SSH key exists
- Verifies host configuration exists in `hosts/<hostname>/`

### 2. **Kexec Boot** (unless `--skip-kexec`)
- Checks if server already in kexec installer
- Downloads NixOS kexec installer (350MB)
- Executes kexec to boot into installer
- Waits for SSH to become available

### 3. **SSH Key Extraction**
- Scans SSH host key from kexec environment
- Converts ED25519 SSH key to age format
- Displays extracted age key

### 4. **SOPS Key Management**
- Compares new age key with existing key in `.sops.yaml`
- If changed:
  - Creates backup: `.sops.yaml.backup`
  - Updates `.sops.yaml` with new age key (using awk for reliability)
  - Re-encrypts all secrets:
    - `users/bmg-secrets.yaml`
    - `hosts/<hostname>/secrets.yaml`

### 5. **Build Verification**
- Builds NixOS configuration to verify it's valid
- Catches errors before deployment

### 6. **Deployment Confirmation**
- Displays warning about disk wiping
- Asks for confirmation (y/n)

### 7. **NixOS Installation**
- Runs `nixos-anywhere` with `--copy-host-keys` flag
- This preserves SSH host keys from kexec to installed system
- Critical for SOPS decryption on first boot!
- Installs complete system closure

### 8. **Post-deployment**
- Server reboots automatically
- Should be accessible via SSH in 2-3 minutes
- SOPS secrets decrypt successfully (SSH keys match)

## Key Features

### ✅ Automated SOPS Key Management
- Detects when SSH host key changes
- Automatically updates `.sops.yaml`
- Re-encrypts all affected secrets
- Creates backups before changes

### ✅ SSH Host Key Persistence
- Uses `--copy-host-keys` with nixos-anywhere
- Ensures SOPS can decrypt secrets on first boot
- Solves the chicken-and-egg problem with SSH keys

### ✅ Robust String Replacement
- Uses `awk` instead of `sed` for .sops.yaml updates
- Handles long age keys (62+ characters) reliably
- No delimiter conflicts or escaping issues

### ✅ User-Friendly Output
- Colored output (green=info, yellow=warn, red=error)
- Progress indicators for each step
- Clear error messages

### ✅ Safety Features
- Pre-flight validation
- Configuration build verification before deployment
- Interactive confirmation for destructive operations
- Backup of `.sops.yaml` before modifications

## Troubleshooting

### SSH Connection Issues

If SSH doesn't work after deployment:
- Wait 3-5 minutes for full boot
- Check Hetzner KVM console
- Verify network configuration in host config

### SOPS Update Failures

If SOPS update fails:
- Check that host is listed in `.sops.yaml`
- Verify age key format is correct
- Restore from `.sops.yaml.backup` if needed

### Build Failures

If configuration doesn't build:
- Fix configuration errors first
- Run `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`
- Review error messages

## Integration

### Add to Devshell

Add to `nix/devshell.nix`:

```nix
commands = [
  {
    name = "deploy-hetzner";
    help = "Deploy to Hetzner server";
    command = "$PRJ_ROOT/packages/scripts/deploy-hetzner-server.sh $@";
  }
];
```

Then use: `deploy-hetzner nubes`

### Makefile

Create targets in `Makefile`:

```makefile
.PHONY: deploy-nubes deploy-nephele

deploy-nubes:
@./packages/scripts/deploy-hetzner-server.sh nubes

deploy-nephele:
@./packages/scripts/deploy-hetzner-server.sh nephele
```

## Important Notes

### SSH Host Key Persistence

The script uses `--copy-host-keys` with nixos-anywhere, which:
- Copies SSH host keys from kexec installer to installed system
- Ensures SOPS can decrypt secrets on first boot
- Prevents "cannot read ssh key" errors
- **Critical:** Without this, SOPS decryption fails and user creation fails!

### Age Key Management

The script automatically:
1. Extracts age key from SSH host key in kexec environment
2. Updates `.sops.yaml` if key changed
3. Re-encrypts all secrets with new key
4. Creates backups before modifications

This ensures secrets are always encrypted with the correct key!

### Supported Hosts

Currently configured hosts:
- **nubes** - Hetzner dedicated server
- **caelus** - Hetzner cloud server (Nebula lighthouse)

To add new hosts:
1. Create `hosts/<hostname>/default.nix`
2. Create `hosts/<hostname>/disk-config.nix`
3. Add host to `.sops.yaml`
4. Create `hosts/<hostname>/secrets.yaml`

## Security Notes

### Authentication
- ✅ Uses SSH key authentication only (no passwords)
- ✅ Requires YubiKey SSH keys for user authentication
- ✅ SOPS secrets are encrypted at rest
- ✅ Age encryption with per-host keys

### Secret Management
- ✅ Secrets encrypted before deployment
- ✅ Automatic key rotation when SSH keys change
- ✅ Backups created before modifications
- ✅ Multiple decryption keys (admin + host)

### Deployment Safety
- ✅ Interactive confirmation required
- ✅ Build verification before deployment
- ✅ Pre-flight checks for configuration
- ✅ Colored output for warnings/errors

## References

- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)
- [Disko Partitioning](https://github.com/nix-community/disko)

## License

MIT License - See SPDX header in script files

## Contributing

When modifying the deployment script:
1. Update this README if behavior changes
2. Test with `--skip-kexec` first (faster iteration)
3. Verify SOPS key management works correctly
4. Check both fresh deployments and re-deployments
