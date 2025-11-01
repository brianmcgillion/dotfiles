# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# nixd Language Server Configuration

This document describes the nixd language server configuration for this repository.

## Overview

nixd is the Nix language server that provides IDE features like:
- Code completion (nixpkgs packages, NixOS options, home-manager options)
- Jump to definition
- Hover documentation
- Code formatting with nixfmt
- Diagnostics and error checking

## Configuration

The nixd configuration is automatically generated when entering any Nix project directory via direnv.

### System-Wide Setup

This repository installs a direnv library function (`use_nixd`) that is available system-wide:

1. **Location**: `~/.config/direnv/lib/nixd.sh` (installed via home-manager)
2. **Usage**: Add `use_nixd` to any project's `.envrc`
3. **Automatic**: Detects project type and generates appropriate `.nixd.json`
4. **Universal**: Works with NixOS configs, home-manager, and generic flakes

### Automatic Setup

1. **direnv** generates `.nixd.json` automatically based on project type
2. The configuration is machine-specific and not tracked in git
3. Works with any editor that supports Language Server Protocol (LSP)
4. Available in all your Nix projects, not just this one

### Configuration Location

- **Library**: `~/.config/direnv/lib/nixd.sh` (system-wide direnv library)
- **Auto-generated**: `.nixd.json` (gitignored, created by `use_nixd`)
- **Source code**: `home/shell/direnv-nixd.sh` (in dotfiles repo)

### What Gets Configured

The generated `.nixd.json` provides:

1. **Flake evaluation target**: Points to your NixOS system configuration
   ```json
   "installable": "/path/to/.dotfiles#nixosConfigurations.<hostname>.config.system.build.toplevel"
   ```

2. **NixOS options**: Completion for NixOS configuration options
   ```json
   "nixos": {
     "expr": "(builtins.getFlake \"/path\").nixosConfigurations.<hostname>.options"
   }
   ```

3. **Home-manager options**: Completion for home-manager user configuration
   ```json
   "home-manager": {
     "expr": "(builtins.getFlake \"/path\").nixosConfigurations.<hostname>.config.home-manager.users.<username>.options"
   }
   ```

4. **Formatting**: Uses nixfmt (RFC 166 standard)
   ```json
   "formatting": {
     "command": ["nixfmt"]
   }
   ```

## Editor Integration

### Emacs (Doom)

nixd is already configured in `~/.config/doom/config.el`:

```elisp
(setq lsp-nix-nixd-server-path "nixd"
      lsp-nix-nixd-formatting-command ["nixfmt"])
```

The `.nixd.json` file is automatically picked up by the nixd LSP server.

### VSCode

Install the "Nix IDE" extension and it will automatically use `.nixd.json`.

### Neovim

Use `nvim-lspconfig` with nixd:

```lua
require'lspconfig'.nixd.setup{}
```

The `.nixd.json` file will be automatically detected.

## Using in Other Projects

To use nixd in any Nix project:

1. **Create or edit `.envrc`**:
   ```bash
   # For flake projects
   use flake
   use_nixd
   ```

   ```bash
   # For non-flake projects
   use nix
   use_nixd
   ```

2. **Allow direnv**:
   ```bash
   direnv allow
   ```

3. **Verify configuration**:
   ```bash
   cat .nixd.json
   ```

The `use_nixd` function automatically detects:
- **NixOS configurations**: Generates config with nixosConfigurations options
- **Home-manager configurations**: Generates config with homeConfigurations options
- **Generic flakes**: Generates config with nixpkgs evaluation
- **Non-flake projects**: Skips generation with a message

## Manual Configuration

If you need to manually generate the configuration without direnv, you can source the library function directly:

```bash
# Source the library
source ~/.config/direnv/lib/nixd.sh

# Run the function
use_nixd
```

Or call the internal functions directly for specific project types:

```bash
# For NixOS configurations
source ~/.config/direnv/lib/nixd.sh
_generate_nixos_nixd_config "$(pwd)" "$(hostname)" "$USER"

# For home-manager configurations
source ~/.config/direnv/lib/nixd.sh
_generate_home_manager_nixd_config "$(pwd)" "$USER" "$(hostname)"

# For generic flakes
source ~/.config/direnv/lib/nixd.sh
_generate_generic_nixd_config "$(pwd)"
```

## Troubleshooting

### nixd not working

1. **Check if nixd is in PATH**:
   ```bash
   which nixd
   ```
   Should return: `/nix/store/...-nixd-<version>/bin/nixd`

2. **Verify .nixd.json exists**:
   ```bash
   cat .nixd.json
   ```
   Should show your configuration with correct paths.

3. **Re-allow direnv**:
   ```bash
   direnv allow
   ```

4. **Check LSP server is running** (Emacs):
   ```
   M-x lsp-describe-session
   ```

### Completions not working

1. **Verify flake evaluation works**:
   ```bash
   nix eval .#nixosConfigurations.$(hostname).options --apply 'x: "ok"'
   ```

2. **Check nixd logs** (Emacs):
   ```
   M-x lsp-workspace-show-log
   ```

3. **Restart LSP server** (Emacs):
   ```
   M-x lsp-workspace-restart
   ```

### Wrong host configuration

The `.nixd.json` is hostname-specific. If you copy the repository to a different machine:

1. Exit and re-enter the directory (triggers direnv)
2. Or run: `direnv reload`
3. Or manually regenerate `.nixd.json` (see Manual Configuration above)

## Performance Tuning

The configuration uses 3 workers by default. For better performance on multi-core systems:

```json
{
  "eval": {
    "workers": 8
  }
}
```

Adjust based on your CPU cores.

## References

- [nixd GitHub](https://github.com/nix-community/nixd)
- [nixd Documentation](https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Repository structure
- [README.md](../README.md) - General documentation
