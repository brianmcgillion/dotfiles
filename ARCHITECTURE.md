# Architecture Documentation

This NixOS configuration uses a modular architecture for better maintainability, reusability, and clarity.

## Directory Structure

```
.
├── flake.nix              # Main flake entry point
├── modules/               # NixOS system modules
│   ├── default.nix       # Module exports
│   ├── profiles/         # High-level system profiles
│   │   ├── common.nix    # Base configuration (nix settings, SSH config, etc.)
│   │   ├── client.nix    # Desktop/laptop profile
│   │   └── server.nix    # Server/headless profile
│   ├── features/         # Feature modules with explicit enable options
│   │   ├── ai/           # AI/ML tooling
│   │   │   └── default.nix
│   │   ├── desktop/      # Desktop environment features
│   │   │   ├── audio.nix
│   │   │   ├── desktop-manager.nix
│   │   │   └── yubikey.nix
│   │   ├── development/  # Development tools
│   │   │   ├── emacs.nix
│   │   │   └── emacs-ui.nix
│   │   ├── networking/   # Network features
│   │   │   └── nebula.nix
│   │   ├── security/     # Security features
│   │   │   ├── hardening.nix
│   │   │   ├── fail2ban.nix
│   │   │   └── sshd.nix
│   │   └── system/       # System-level features
│   │       ├── locale-fonts.nix
│   │       ├── packages.nix
│   │       └── xdg.nix
│   ├── hardware/         # Hardware-specific configurations
│   │   └── nvidia.nix
│   └── users/            # User management
│       ├── brian/
│       │   ├── default.nix    # NixOS user config
│       │   ├── bmg-secrets.yaml
│       │   └── hm-profile/    # Home-manager profile
│       │       ├── default.nix
│       │       ├── git.nix
│       │       └── emacs.nix
│       ├── root.nix
│       └── groups.nix
├── hosts/                # Host-specific configurations
│   ├── arcadia/          # Desktop with NVIDIA
│   ├── argus/            # ML desktop with NVIDIA RTX 5080
│   ├── minerva/          # Laptop with SSH
│   ├── nubes/          # Hetzner server
│   └── caelus/           # Hetzner cloud (Nebula lighthouse)
├── home/                 # Home-manager configurations
│   ├── profiles/
│   │   ├── client.nix    # Desktop user environment
│   │   └── server.nix    # Minimal server user environment
│   └── features/         # Home-manager feature modules
│       ├── apps/
│       ├── browsers/
│       ├── development/
│       ├── security/
│       └── shell/
├── packages/             # Custom packages and overlays
│   ├── rebiber/
│   └── scripts/
└── nix/                  # Flake infrastructure
    ├── checks.nix
    ├── deployments.nix
    ├── devshell.nix
    ├── nixpkgs.nix
    └── treefmt.nix
```

## Design Principles

### 1. Explicit Feature Enabling
All features are declared with clear `enable` options under the `features` namespace:

```nix
features = {
  desktop.audio.enable = true;
  development.emacs.enable = true;
  networking.nebula.enable = true;
  security.sshd.enable = true;
};
```

### 2. Profile System
Profiles are high-level configurations that enable sensible defaults for different system types:

- **`profile-common`**: Base configuration for all systems (nix settings, SSH config, build machines)
- **`profile-client`**: Desktop/laptop systems (GNOME, audio, development tools, home-manager)
- **`profile-server`**: Headless servers (SSH, fail2ban, minimal packages, home-manager)

### 3. Feature Modules
Each feature module follows this pattern:

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
    enable = lib.mkEnableOption "feature description";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Feature implementation
  };
}
```

### 4. Host Configuration
Host configurations are minimal and declarative:

```nix
{
  imports = [
    self.nixosModules.profile-client
    self.nixosModules.hardware-nvidia
  ];

  features.networking.nebula = {
    enable = true;
    ca = config.sops.secrets.nebula-ca.path;
    # ...
  };

  # Hardware-specific config
  hardware.cpu.amd.updateMicrocode = true;

  # Network interfaces
  networking.hostName = "arcadia";

  system.stateVersion = "22.05";
}
```

## Current System Configurations

### Client Systems

#### arcadia
- **Type**: Desktop
- **Profile**: client
- **Hardware**: AMD CPU, NVIDIA GPU
- **Features**: GNOME, audio, Emacs, Nebula network

#### argus
- **Type**: ML Desktop
- **Profile**: client
- **Hardware**: Intel CPU, NVIDIA RTX 5080 GPU
- **Features**: GNOME, audio, Emacs, Nebula network, AI/ML (Ollama + Goose)

#### minerva
- **Type**: Laptop (Lenovo ThinkPad X1 9th Gen)
- **Profile**: client
- **Hardware**: Intel CPU, encrypted storage
- **Features**: GNOME, audio, Emacs, Nebula network, SSH server

### Server Systems

#### nubes
- **Type**: Hetzner dedicated server
- **Profile**: server
- **Hardware**: AMD CPU, disko-managed disks
- **Features**: SSH, fail2ban, Nebula network

#### caelus
- **Type**: Hetzner cloud server (Nebula lighthouse)
- **Profile**: server
- **Hardware**: Intel CPU (virtualized), disko-managed disks
- **Features**: SSH, fail2ban, Nebula network (lighthouse mode)

## Adding a New Host

1. Create host directory: `mkdir -p hosts/newhostname`
2. Create `hosts/newhostname/default.nix`:

```nix
{
  self,
  lib,
  ...
}:
{
  imports = [
    self.nixosModules.profile-client  # or profile-server
    # Add hardware-specific modules if needed
  ];

  # Enable desired features
  features = {
    desktop.audio.enable = true;
    # ...
  };

  # Hardware configuration
  nixpkgs.hostPlatform = "x86_64-linux";

  # ... rest of hardware config

  system.stateVersion = "24.11";
}
```

3. Add to `hosts/default.nix`:

```nix
flake.nixosModules = {
  # ...
  host-newhostname = import ./newhostname;
};

flake.nixosConfigurations = {
  # ...
  newhostname = lib.nixosSystem {
    inherit specialArgs;
    modules = [ self.nixosModules.host-newhostname ];
  };
};
```

## Adding a New Feature

1. Create feature module: `modules/features/<category>/<feature>.nix`
2. Define options and configuration:

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
    enable = lib.mkEnableOption "feature description";
  };

  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

3. Export in `modules/default.nix`:

```nix
flake.nixosModules = {
  # ...
  feature-<name> = import ./features/<category>/<feature>.nix;
};
```

4. Import in relevant profile if it should be enabled by default:

```nix
imports = [
  # ...
  self.nixosModules.feature-<name>
];

config = {
  features.<category>.<feature>.enable = lib.mkDefault true;
};
```

## Benefits of This Architecture

1. **Clarity**: Easy to see what's enabled on each host
2. **Reusability**: Features can be shared across different system types
3. **Maintainability**: Changes to features are isolated and don't affect other parts
4. **Testability**: Individual features can be tested independently
5. **Documentation**: Structure self-documents the system capabilities
6. **Flexibility**: Easy to override defaults per-host
7. **Type Safety**: Explicit options provide better error messages

## Migration Notes

### Old Structure → New Structure

- `nixos/*.nix` → `modules/features/*/` (with options)
- `hosts/common.nix` → `modules/profiles/common.nix`
- `hosts/common-client.nix` → `modules/profiles/client.nix`
- `hosts/common-server.nix` → `modules/profiles/server.nix`
- `users/*.nix` → `modules/users/`
- `config.setup.device.isClient` → Profile selection
- `config.my-nebula-network` → `config.features.networking.nebula`

### Testing the Migration

All hosts have been verified to build successfully:
```bash
nix flake check
nixos-rebuild build --flake .#arcadia
nixos-rebuild build --flake .#minerva
nixos-rebuild build --flake .#nubes
nixos-rebuild build --flake .#caelus
```

To apply on current system:
```bash
rebuild-host  # or: sudo nixos-rebuild switch --flake .#$HOSTNAME
```
