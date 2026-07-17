# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

NixOS flake-based configuration managing multiple systems (desktops, laptops, servers) with a modular architecture. For detailed architecture, see ARCHITECTURE.md.

## Key Commands

```bash
# Development environment (provides all tools: cachix, sops, treefmt, etc.)
nix develop

# Build and deploy
nixos-rebuild build --flake .#<hostname>    # Build without switching
sudo nixos-rebuild switch --flake .#$HOSTNAME  # Deploy locally
nix develop -c deploy-nubes                 # Deploy remotely with deploy-rs (also: deploy-caelus, deploy-argus)
nix develop -c deploy-hetzner-server <host> # Initial provisioning via nixos-anywhere/kexec

# Code quality (REQUIRED before commits)
nix fmt                           # Format all files
nix fmt -- --fail-on-change       # Check formatting
nix flake check                   # Run all checks (pre-commit hooks, package builds, deploy-rs)
nix develop --command reuse lint  # Verify license headers

# Testing
nixos-rebuild dry-run --flake .#<hostname>      # Fast validation
nixos-rebuild dry-activate --flake .#<hostname> # Build + show activation
```

Available hosts: `arcadia` (desktop), `argus` (ML desktop, RTX 5080), `minerva` (laptop), `nubes` (dedicated server), `caelus` (cloud server)

## Architecture

**Module Pattern**: Features use explicit enable options under the `features` namespace:
```nix
features.desktop.audio.enable = true;
features.development.emacs.enable = true;
features.security.sshd.enable = true;
```

**Directory Structure**:
- `modules/profiles/` - High-level profiles: common (base), client (desktop), server (headless)
- `modules/features/` - Feature modules by category (ai, desktop, development, networking, security, system)
- `hosts/` - Minimal host configs that import profiles and enable features
- `home/` - Home-manager user environment configurations
- `packages/` - Custom packages and overlays
- `nix/` - Flake infrastructure (checks, deployments, devshell, treefmt)

**Feature Module Template**:
```nix
{ config, lib, pkgs, ... }:
let cfg = config.features.<category>.<feature>;
in {
  options.features.<category>.<feature> = {
    enable = lib.mkEnableOption "<description>";
  };
  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

## Code Standards

- **Formatting**: All files must pass `nix fmt` (nixfmt RFC 166, shellcheck, shfmt, statix, deadnix, keep-sorted, nixf-diagnose)
- **License headers**: New files require SPDX MIT headers; verify with `reuse lint`
- **No trailing whitespace**: Enforced by the pre-commit hooks and `nix flake check`
- **File naming**: kebab-case for files (`feature-name.nix`)
- **Option naming**: feature attribute names mirror their kebab-case file names (`features.desktop.desktop-manager`); leaf options within a feature use camelCase (`lighthouseAddress`)

## Secrets Management

Uses SOPS-nix with age encryption. Secrets are in `secrets.yaml` and host-specific `secrets.yaml` files.
The admin recipients include the software age key plus the YubiKey age recipients (any one can decrypt).
```bash
sops secrets.yaml                    # Edit secrets
sops updatekeys secrets.yaml         # Update after adding host keys
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age  # Get host age key
```
