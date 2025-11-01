# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# nixd Quick Start Guide

Quick reference for enabling nixd language server in any Nix project.

## Prerequisites

- This dotfiles configuration deployed (installs the direnv library)
- direnv installed and enabled
- nixd installed (included in this configuration)

## Enable nixd in Any Project

### Step 1: Create `.envrc`

In your project root, create or edit `.envrc`:

**For flake projects:**
```bash
use flake
use_nixd
```

**For non-flake projects:**
```bash
use nix
use_nixd
```

### Step 2: Allow direnv

```bash
direnv allow
```

### Step 3: Verify

Check that `.nixd.json` was created:
```bash
cat .nixd.json
```

## What Gets Configured

The `use_nixd` function automatically detects your project type:

### NixOS Configuration Projects
- Flakes with `nixosConfigurations`
- Examples: System configurations, multi-host setups
- **Provides**: NixOS options, home-manager options, system packages

### Home-Manager Projects
- Flakes with `homeConfigurations`
- Examples: User environment configurations
- **Provides**: Home-manager options, user packages

### Generic Flake Projects
- Flakes with packages, devShells, or other outputs
- Examples: Applications, development environments
- **Provides**: nixpkgs evaluation, package definitions

## Editor Support

Once `.nixd.json` exists, your editor automatically gets:

✅ **Completion** for:
- NixOS options (services, hardware, networking, etc.)
- Home-manager options (programs, services, etc.)
- nixpkgs packages and attributes
- Function parameters and let bindings

✅ **Jump to definition** for:
- Package definitions
- Option declarations
- Function definitions

✅ **Hover documentation**:
- Option descriptions
- Package metadata
- Type information

✅ **Diagnostics**:
- Syntax errors
- Type errors
- Undefined references

✅ **Formatting**:
- Automatic formatting with nixfmt (RFC 166 standard)

## Examples

### Example 1: NixOS Configuration

```bash
cd ~/my-nixos-config
cat > .envrc <<EOF
use flake
use_nixd
EOF
direnv allow
```

Result: `.nixd.json` with NixOS options from your configurations.

### Example 2: Nix Flake Package

```bash
cd ~/my-nix-package
cat > .envrc <<EOF
use flake
use_nixd
EOF
direnv allow
```

Result: `.nixd.json` with nixpkgs evaluation.

### Example 3: Development Shell

```bash
cd ~/my-project
cat > .envrc <<EOF
use flake  # or: nix flake develop
use_nixd
EOF
direnv allow
```

Result: `.nixd.json` with development environment context.

## Troubleshooting

### `.nixd.json` not created

**Check**: Is there a `flake.nix`?
```bash
ls flake.nix
```

If no flake exists, `use_nixd` skips generation. Convert to a flake first:
```bash
nix flake init
```

### Wrong configuration generated

**Check**: Project type detection
```bash
nix flake show --json | jq 'keys'
```

The function looks for `nixosConfigurations`, `homeConfigurations`, or falls back to generic.

### LSP not working

**Verify**: nixd is available
```bash
which nixd
```

**Restart**: Your editor's LSP server
- Emacs: `M-x lsp-workspace-restart`
- VSCode: "Developer: Reload Window"
- Neovim: `:LspRestart`

## Adding to .gitignore

Always ignore the generated configuration:
```bash
echo ".nixd.json" >> .gitignore
```

This is machine-specific and should not be committed.

## See Also

- [NIXD_LSP.md](NIXD_LSP.md) - Full documentation
- [nixd GitHub](https://github.com/nix-community/nixd)
