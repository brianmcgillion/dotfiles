<!--
SPDX-License-Identifier: MIT
SPDX-FileCopyrightText: 2022-2025 Brian McGillion
-->

# dotfiles Development Instructions

**dotfiles** is a personal NixOS configuration for desktops, laptops, and servers using a flake-based modular architecture.

**CRITICAL: Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Serena Code Analysis (MCP Server)

**IMPORTANT: At the start of every session, check if Serena is available by running `serena-get_current_config` or `serena-check_onboarding_performed`. If Serena is enabled, use it for ALL code analysis and investigation tasks.**

### When to Use Serena

Use Serena's semantic analysis tools for:
- **Understanding NixOS module structure**: Find symbols, analyze imports, trace feature dependencies
- **Investigating configuration options**: Find where options are defined, used, or referenced
- **Analyzing function definitions**: Understand NixOS module functions, overlays, and package definitions
- **Tracking changes**: Find all references to a specific option or function before modifications
- **Code navigation**: Browse symbol hierarchies in Nix modules without reading entire files

### Standard Serena Workflow for NixOS

1. **Check session state**: `serena-check_onboarding_performed` to verify Serena is ready
2. **List available memories**: `serena-list_memories` to see existing project knowledge
3. **Read relevant memories**: `serena-read_memory` for context on specific areas (e.g., "features-architecture")
4. **Find symbols/options**: Use `serena-find_symbol` to locate NixOS options, functions, or module definitions
5. **Analyze references**: Use `serena-find_referencing_symbols` to see where options/functions are used
6. **Get file overview**: Use `serena-get_symbols_overview` to understand module structure
7. **Create memories**: Use `serena-write_memory` to document findings for future sessions

### Example Serena Commands

```
# Find a feature module definition
serena-find_symbol --name_path_pattern "features.desktop.audio.enable"

# See all references to a specific option
serena-find_referencing_symbols --name_path "enable" --relative_path "modules/features/desktop/audio.nix"

# Get overview of a module's exports
serena-get_symbols_overview --relative_path "modules/features/security/sshd.nix"

# Search for SOPS-related patterns
serena-search_for_pattern --substring_pattern "sops\\.secrets\\." --restrict_search_to_code_files true
```

**Note**: If Serena is not available in the session, fall back to standard grep/view tools for code analysis.

## Context7 Documentation Lookup (MCP Server)

**IMPORTANT: Use Context7 for up-to-date documentation on NixOS, Nix language, Home Manager, and other Nix ecosystem tools.**

### When to Use Context7

Use Context7 for:
- **NixOS options documentation**: Understanding system configuration options and their usage
- **Home Manager options**: Looking up home-manager configuration syntax and available options
- **Nix language features**: Getting current Nix language syntax, builtins, and best practices
- **Package information**: Understanding package attributes, overlays, and derivation patterns
- **Module system**: Learning about NixOS module structure, option definitions, and imports

### Standard Context7 Workflow

1. **Resolve library ID**: Use `context7-resolve-library-id` to find the correct library
   - Examples: "nixos", "home-manager", "nix", "nixpkgs"
2. **Get documentation**: Use `context7-get-library-docs` with the resolved library ID
   - Use `mode='code'` (default) for API references, options, and code examples
   - Use `mode='info'` for conceptual guides, tutorials, and architecture
3. **Iterate with pagination**: If context is insufficient, use `page=2`, `page=3`, etc.
4. **Focus with topics**: Use the `topic` parameter to narrow documentation scope

### Example Context7 Commands

```
# Find NixOS documentation library
context7-resolve-library-id --libraryName "nixos"

# Get NixOS options documentation (code mode)
context7-get-library-docs --context7CompatibleLibraryID "/NixOS/nixos" --mode "code" --topic "services.sshd"

# Get Home Manager options
context7-get-library-docs --context7CompatibleLibraryID "/nix-community/home-manager" --mode "code" --topic "programs.git"

# Get conceptual Nix language guide (info mode)
context7-get-library-docs --context7CompatibleLibraryID "/NixOS/nix" --mode "info" --topic "language"

# Get SOPS-nix documentation
context7-get-library-docs --context7CompatibleLibraryID "/Mic92/sops-nix" --mode "code" --topic "secrets"
```

### Common NixOS Libraries

- `/NixOS/nixos` - NixOS system configuration options
- `/NixOS/nixpkgs` - Nixpkgs package set and functions
- `/NixOS/nix` - Nix language and package manager
- `/nix-community/home-manager` - Home Manager user environment management
- `/Mic92/sops-nix` - SOPS secrets management for NixOS
- `/numtide/flake-utils` - Flake utility functions

**Note**: Always resolve library IDs first unless you know the exact Context7-compatible ID format.

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
