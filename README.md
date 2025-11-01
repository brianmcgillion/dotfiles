
## Introduction

Flake based nixos configuration. Intended as a private config, so it is not abstracted to bootstrap any other system than my own.


## Setup

1. Acquire NixOS 21.11 or newer:
   ```sh
   # downlod nixos-unstable
   wget -O nixos.iso https://channels.nixos.org/nixos-unstable/latest-gnome-minimal-x86_64-linux.iso

   # Write to usb drive
   cp nixos.iso /dev/sdX
   ```

2. Boot the installer.

3. Define partitions and mount your root to `/mnt`.

5. Install this config:
   ```sh
   nix-shell -p git nixFlakes

   git clone https://github.com/brianmcgillion/dotfiles /etc/dotfiles
   cd /etc/dotfiles

   # Set HOST: the hostname for the new system
   HOST=...

   # Create a host config in `hosts/nixos/` and add it to the repo:
   mkdir -p hosts/nixos/$HOST
   nixos-generate-config --root /mnt --dir /etc/dotfiles/hosts/nixos/$HOST
   rm -f hosts/nixos/$HOST/configuration.nix

   Modify inclusions as needed.

   nano hosts/nixos/$HOST/default.nix  # configure this for yo
   git add hosts/nixos/$HOST

   # Install nixOS

   # Then move the dotfiles to the mounted drive!
   mv /etc/dotfiles /mnt/etc/dotfiles
   ```

6. Then reboot to a built system.

## Update

    nix flake update
    sudo nixos-rebuild switch --flake .#MACHINE_NAME

## Developer Tools

### nixd Language Server

This configuration includes system-wide nixd language server support for all Nix projects.

**Automatic Setup**: The `use_nixd` direnv function is installed in `~/.config/direnv/lib/` and available globally.

**Quick Start** - Enable in any Nix project:

```bash
# Add to your project's .envrc
use flake  # or: use nix
use_nixd

# Allow direnv
direnv allow
```

The `use_nixd` function automatically:
- Detects your project type (NixOS config, home-manager, generic flake)
- Generates appropriate `.nixd.json` configuration
- Provides IDE features: completion, jump-to-definition, hover docs, formatting

**Documentation**:
- [NIXD_QUICKSTART.md](docs/NIXD_QUICKSTART.md) - Quick reference
- [NIXD_LSP.md](docs/NIXD_LSP.md) - Full documentation

**Editor Support**: Works with Emacs (configured), VSCode, Neovim, and any LSP-compatible editor.

