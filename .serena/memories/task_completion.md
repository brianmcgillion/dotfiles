# Task Completion Checklist

## Before Committing

### 1. Format Code
```bash
nix fmt
```
Or check without changes:
```bash
nix fmt -- --fail-on-change
```

### 2. Check License Compliance
```bash
nix develop --command reuse lint
```
Ensure all new files have SPDX headers:
```nix
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
```

### 3. Run All Checks
```bash
nix flake check
```
This runs:
- pre-commit hooks
- treefmt formatting check
- deploy-rs activation validation
- deploy schema validation

### 4. Test Build
For the affected host(s):
```bash
# Dry-run (fast, shows what would change)
nixos-rebuild dry-run --flake .#HOSTNAME

# Full build (slower, actually builds)
nixos-rebuild build --flake .#HOSTNAME
```

### 5. Verify Module Exports (if adding modules)
```bash
nix eval .#nixosModules --apply 'x: builtins.attrNames x'
nix eval .#homeModules --apply 'x: builtins.attrNames x'
```

## Pre-commit Hooks
Hooks run automatically on `git push` (configured for `pre-push` stage):
- treefmt formatting
- REUSE license compliance
- end-of-file-fixer
- trim-trailing-whitespace

## After Merging

### Deploy to Local System
```bash
rebuild-host
# or: sudo nixos-rebuild switch --flake .#$HOSTNAME
```

### Deploy to Remote Servers
```bash
# Using system scripts
rebuild-nubes
rebuild-caelus

# Or using deploy-rs (from devshell)
nix develop
deploy-rs .#nubes
deploy-rs .#caelus
```

## Common Issues

### New File Not Found by Nix
Add untracked files to git:
```bash
git add path/to/new/file.nix
```

### Formatting Failures
Run formatter and check diff:
```bash
nix fmt
git diff
```

### Module Not Exported
Ensure module is added to `modules/default.nix` or imported via `imports = [...]`
