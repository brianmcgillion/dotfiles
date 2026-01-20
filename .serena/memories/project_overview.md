# Project Overview

## Purpose
Personal NixOS configuration (dotfiles) for managing multiple machines using a flake-based modular architecture. Manages desktops, laptops, and servers.

## Machines Managed
- **arcadia** - Desktop with AMD CPU and NVIDIA GPU (client profile)
- **minerva** - Laptop, Lenovo ThinkPad X1 (client profile)
- **nubes** - Hetzner dedicated server (server profile)
- **caelus** - Hetzner cloud server, Nebula lighthouse (server profile)

## Tech Stack
- **Nix/NixOS** - System configuration language and OS
- **Flake-parts** - Modular flake structure using NixOS module system
- **Home-manager** - User environment management
- **SOPS-nix** - Secrets management
- **Deploy-rs** - Remote deployment tool
- **Disko** - Declarative disk partitioning
- **Treefmt** - Multi-language code formatting

## Directory Structure
```
.
├── flake.nix           # Main flake entry point
├── modules/            # NixOS system modules
│   ├── profiles/       # High-level profiles (common, client, server)
│   ├── features/       # Feature modules with enable options
│   ├── hardware/       # Hardware-specific configs
│   └── users/          # User management (brian/, root.nix, groups.nix)
├── hosts/              # Host-specific configurations
├── home/               # Home-manager configurations
│   └── profiles/       # Home profiles (client.nix, server.nix)
├── packages/           # Custom packages and scripts
└── nix/                # Flake infrastructure (checks, devshell, treefmt)
```

## Key Design Patterns

### Feature Modules
Features use explicit enable options under the `features` namespace:
```nix
features.desktop.audio.enable = true;
features.development.emacs.enable = true;
features.security.sshd.enable = true;
```

### Profile System
- `profile-common` - Base for all systems
- `profile-client` - Desktop/laptop systems
- `profile-server` - Headless servers

### User Modules (flake-parts pattern)
User directories export both NixOS and home-manager modules:
```nix
# modules/users/brian/default.nix
_: {
  flake = {
    nixosModules.user-brian = import ./nixos.nix;
    homeModules.user-profile-brian = import ./hm-profile;
  };
}
```
