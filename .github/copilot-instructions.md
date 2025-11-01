<!--
SPDX-License-Identifier: MIT
SPDX-FileCopyrightText: 2022-2025 Brian McGillion
-->

# dotfiles Development Instructions

**dotfiles** is a personal NixOS configuration for desktops, laptops, and servers using a flake-based modular architecture.

**CRITICAL: Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Project Overview

This repository manages NixOS configurations for multiple machines:
- **arcadia** - Desktop system with NVIDIA GPU (local)
- **minerva** - Laptop system (local)
- **caelus** - Hetzner cloud server (remote, Nebula lighthouse)
- **nephele** - Hetzner dedicated server (remote)

### Architecture

The configuration uses a modular architecture:
- **`modules/`** - NixOS system modules with profiles and features
  - **`profiles/`** - High-level configurations (common, client, server)
  - **`features/`** - Explicit feature modules (desktop, development, networking, security, system)
  - **`hardware/`** - Hardware-specific configurations
  - **`users/`** - User management
- **`hosts/`** - Host-specific configurations
- **`home/`** - Home-manager configurations
- **`packages/`** - Custom packages and overlays
- **`nix/`** - Flake infrastructure (checks, deployments, devshell, treefmt)

Features are explicitly enabled using the `features` namespace:
```nix
features.desktop.audio.enable = true;
features.development.emacs.enable = true;
features.security.sshd.enable = true;
```

## Prerequisites and Setup

### Initial Setup
- Install Nix package manager: `curl -L https://nixos.org/nix/install | sh`
- Enable flakes: `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`
- **CRITICAL**: For cross-compilation, set up an AArch64 remote builder: https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html

### Development Environment
Enter the development shell to access all tools:
```bash
nix develop
```

This provides: cachix, nix-eval-jobs, nix-fast-build, nix-output-monitor, nix-tree, sops, ssh-to-age, treefmt, and all formatting tools.

## Code Quality Standards

### **ALWAYS Strip Trailing Whitespace**
- **Automatically remove trailing whitespace** from any files you create or modify
- **Use sed command**: `sed -i 's/[[:space:]]*$//' filename` to clean files
- **Verify cleanup**: Ensure no trailing whitespace remains before staging changes
- **Project-wide consistency**: Maintain clean, professional code formatting standards

### **File Formatting Requirements**
- **All commits must be properly formatted** using treefmt before making a PR
- **Run formatting**: `nix fmt` or `nix fmt -- --fail-on-change`
- **License headers**: Always add proper SPDX license headers to new files using MIT license
- **No trailing whitespace**: Clean, professional code standards


## Development Workflow

### Build Targets and Commands

**Important Nix Flake Commands:**

- **Development shell**: `nix develop` - Enters the development environment with all tools
- **Build all systems**: `nix flake show --all-systems` - Validates flake and shows all outputs
- **Format code**: `nix fmt` - Formats all files using treefmt
- **Check formatting**: `nix fmt -- --fail-on-change` - Verifies formatting without changes
- **Run checks**: `nix flake check` - Runs all checks (pre-commit, treefmt, deployments)
- **Build specific host**: `nixos-rebuild build --flake .#<hostname>` - Builds a specific NixOS configuration

**Available NixOS Configurations:**
- `arcadia` - NixOS system configuration
- `caelus` - NixOS system configuration
- `minerva` - NixOS system configuration
- `nephele` - NixOS system configuration

### Code Formatting and Quality Checks

**CRITICAL: All commits must be properly formatted using treefmt before making a PR**

- **ALWAYS format code before committing**: `nix fmt` or `nix fmt -- --fail-on-change`
- **ALWAYS run license check**: `nix develop --command reuse lint`
- **ALWAYS run all checks**: `nix flake check` - Includes pre-commit, treefmt, and deployment checks
- **These checks must pass** or CI will fail

The project uses treefmt for consistent code formatting across multiple languages and tools:
- **Nix files**: nixfmt (RFC 166 standard), deadnix (removes dead code), statix (anti-patterns), nixf-diagnose (diagnostics with auto-fix)
- **Shell scripts**: shellcheck (linting), shfmt (formatting)
- **General**: keep-sorted (maintains sorted lists)

Pre-commit hooks run on `pre-push` and include:
- treefmt formatting
- REUSE license compliance
- end-of-file-fixer
- trim-trailing-whitespace

### Testing

Run all checks to validate changes:
```bash
nix flake check  # Runs all checks including:
                 # - pre-commit-check
                 # - treefmt
                 # - deploy-activate (validates deployment configs)
                 # - deploy-schema (validates deployment JSON schema)
```

Individual checks can be built with:
```bash
nix build .#checks.x86_64-linux.pre-commit-check
nix build .#checks.x86_64-linux.treefmt
```

**Test NixOS configurations before deployment:**

Dry-run tests (fast, shows what would change without building):
```bash
# Local hosts
nixos-rebuild dry-run --flake .#arcadia
nixos-rebuild dry-run --flake .#minerva

# Remote hosts
nixos-rebuild dry-run --flake .#nephele --target-host "root@nephele"
nixos-rebuild dry-run --flake .#caelus --target-host "root@caelus"
```

Dry-activate tests (builds and shows activation script without applying):
```bash
# Local hosts
nixos-rebuild dry-activate --flake .#arcadia
nixos-rebuild dry-activate --flake .#minerva

# Remote hosts (builds locally, activates on remote)
nixos-rebuild dry-activate --flake .#nephele --target-host "root@nephele"
nixos-rebuild dry-activate --flake .#caelus --target-host "root@caelus"
```

These commands validate configuration changes without affecting running systems. Remote hosts require SSH access and use `--target-host` to deploy configurations built locally.

## Deployment

### Local Systems
Deploy to the current machine:
```bash
sudo nixos-rebuild switch --flake .#$HOSTNAME
```

### Remote Systems
Deploy to remote hosts (builds locally, activates remotely):
```bash
nixos-rebuild switch --flake .#nephele --target-host "root@nephele"
nixos-rebuild switch --flake .#caelus --target-host "root@caelus"
```

Convenience scripts are available in the dev shell:
- `rebuild-host` - Rebuild current host
- `rebuild-nephele` - Deploy to nephele
- `rebuild-caelus` - Deploy to caelus
- `update-host` - Update flake inputs

### New Server Provisioning

For provisioning a new server from scratch:

1. **Boot into NixOS kexec image**:
   ```bash
   curl -L https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
   /root/kexec/run
   ```

2. **Generate hardware configuration**:
   ```bash
   nixos-generate-config --no-filesystems --root /mnt
   ```

3. **Create host configuration** in `hosts/` using disko for disk partitioning

4. **Set up SOPS secrets**:
   ```bash
   # Get the host's age key from SSH key
   ssh-keyscan SERVER | ssh-to-age
   # or from the host itself:
   cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
   
   # Add key to .sops.yaml
   # Create host secrets
   sops hosts/SERVER/secrets.yaml
   
   # Update all common secrets with new key
   sops updatekeys secrets.yaml
   sops updatekeys users/bmg-secrets.yaml
   ```

5. **Deploy using nixos-anywhere**:
   ```bash
   nix run github:nix-community/nixos-anywhere -- --flake .#<server-config> root@<IP address>
   ```
   
   **WARNING**: This wipes and recreates the disk partitioning scheme!

## Common Tasks

### Updating Dependencies
```bash
nix flake update              # Update all inputs
nix flake lock --update-input nixpkgs  # Update specific input
```

### Building Without Switching
```bash
nixos-rebuild build --flake .#<hostname>
```

### Viewing Configuration
```bash
nix flake show --all-systems   # Show all flake outputs
nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel  # Eval system closure
```

### Garbage Collection
```bash
nix-collect-garbage -d        # Delete old generations
sudo nix-collect-garbage -d   # Delete old system generations
```

## Troubleshooting

### Build Failures
- Check if all pre-commit hooks pass: `nix flake check`
- Ensure formatting is correct: `nix fmt -- --fail-on-change`
- Verify license headers: `nix develop --command reuse lint`
- Check for Nix anti-patterns: `statix check`

### Remote Deployment Issues
- Verify SSH access: `ssh root@<hostname>`
- Check if host is in SSH config or use IP address
- Ensure remote builder is configured for cross-compilation
- Use `--show-trace` for detailed error output

### Secrets Management
- Decrypt secrets manually: `sops <path/to/secrets.yaml>`
- Verify age keys are correct in `.sops.yaml`
- Ensure all secrets are updated after adding new hosts: `sops updatekeys <file>`

## Project Standards

### Module Structure
When creating new feature modules:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.<category>.<feature>;
in
{
  options.features.<category>.<feature> = {
    enable = lib.mkEnableOption "<feature description>";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Implementation...
  };
}
```

### File Organization
- Host-specific configs go in `hosts/<hostname>/`
- Reusable features go in `modules/features/`
- User configurations go in `home/`
- Custom packages go in `packages/`

### Naming Conventions
- Use kebab-case for file names: `feature-name.nix`
- Use camelCase for option names: `features.category.featureName.enable`
- Host names should be lowercase: `arcadia`, `nephele`

