# Architecture Documentation

This NixOS configuration uses a modular architecture for better maintainability, reusability, and clarity.

## Directory Structure

The tree below shows the layout with representative examples; per-category
file lists are not exhaustive (see the directories themselves for the
authoritative contents).

```
.
├── flake.nix              # Main flake entry point
├── modules/               # NixOS system modules
│   ├── default.nix       # Module exports (paths, one per profile/feature)
│   ├── profiles/         # High-level system profiles
│   │   ├── common.nix    # Base configuration (nix settings, SSH known hosts, sops, ...)
│   │   ├── client.nix    # Desktop/laptop profile
│   │   └── server.nix    # Server/headless profile
│   ├── features/         # Feature modules with explicit enable options
│   │   ├── ai/           # AI/ML tooling (ollama)
│   │   ├── desktop/      # audio, desktop-manager, keyd, power-management, yubikey
│   │   ├── development/  # emacs, docker, binaryninja, embedded/RE toolchains, ...
│   │   ├── networking/   # nebula, wireguard
│   │   ├── security/     # hardening, fail2ban, sshd
│   │   └── system/       # locale-fonts, packages, xdg, github-token, remote-builders
│   ├── hardware/         # Hardware-specific configurations
│   │   └── nvidia.nix
│   └── users/            # User management
│       ├── brian/
│       │   ├── default.nix    # flake-parts module exporting user-brian + hm profile
│       │   ├── nixos.nix      # NixOS user config (account, keys, home-manager wiring)
│       │   ├── bmg-secrets.yaml
│       │   └── hm-profile/    # Personal home-manager profile (git identity, doom emacs)
│       ├── root.nix
│       └── groups.nix
├── hosts/                # Host-specific configurations
│   ├── arcadia/          # Desktop with NVIDIA (AMD CPU)
│   ├── argus/            # ML desktop with NVIDIA RTX 5080 (AMD CPU)
│   ├── minerva/          # Laptop (ThinkPad X1)
│   ├── nubes/            # Hetzner dedicated server
│   └── caelus/           # Hetzner cloud (Nebula lighthouse)
├── home/                 # Home-manager configurations
│   ├── default.nix       # flake-parts module exporting the home profiles
│   ├── home.nix          # Shared base (stateVersion, xdg)
│   ├── profiles/
│   │   ├── client.nix    # Desktop user environment (imports the dirs below)
│   │   └── server.nix    # Minimal server user environment (basic shell, fzf, tmux)
│   ├── apps/             # chat, nextcloud, remarkable
│   ├── browsers/         # google-chrome
│   ├── development/      # base-system, embedded, claude, copilot, mcp-servers catalog
│   ├── security/         # ssh-agent + personal ssh aliases
│   └── shell/            # bash, fzf, kitty, ghostty, tmux
├── packages/             # Custom packages and overlays
│   ├── default.nix       # own-pkgs-overlay + perSystem package exports
│   ├── remarkable-sync/  # shared reMarkable sync CLI
│   ├── scripts/          # helper scripts (deploy, rebuild-*, ...)
│   └── ...               # rebiber, svd2py, proploader, uniflash, stm32cubeprogrammer, f28335-dump
├── scripts/              # Repo-level utility scripts (nebula-add-device.sh)
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

- **`profile-common`**: Base configuration for all systems (nix settings, SSH known hosts, sops, hardening)
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

  sops.defaultSopsFile = ./secrets.yaml;

  features.networking.nebula = {
    enable = true;
    useSopsSecrets = true; # ca/key/cert wired from sops.secrets.nebula-*
  };

  # Hardware-specific config
  hardware.cpu.amd.updateMicrocode = true;

  # networking.hostName defaults to the nixosConfigurations attribute name

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
- **Hardware**: AMD CPU, NVIDIA RTX 5080 GPU
- **Features**: GNOME, audio, Emacs, Nebula network, AI/ML (Ollama)

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

3. Add to `hosts/default.nix` — export the host module and append the name
   to the `genAttrs` host list (the hostname is derived from that name):

```nix
flake.nixosModules = {
  # ...
  host-newhostname = ./newhostname;
};

# ...
lib.genAttrs [
  # ...
  "newhostname"
] (name: lib.nixosSystem (mkHost name));
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

3. Export in `modules/default.nix` (as a path, so the module system can
   deduplicate imports):

```nix
flake.nixosModules = {
  # ...
  feature-<name> = ./features/<category>/<feature>.nix;
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
nix flake check   # also runs deploy-rs checks for argus/caelus/nubes
nixos-rebuild build --flake .#arcadia
nixos-rebuild build --flake .#argus
nixos-rebuild build --flake .#minerva
nixos-rebuild build --flake .#nubes
nixos-rebuild build --flake .#caelus
```

To apply on current system:
```bash
rebuild-host  # or: sudo nixos-rebuild switch --flake .#$HOSTNAME
```

## Security Posture Notes

Deliberate trade-offs, documented so they are not "fixed" by accident:

- **Passwordless wheel sudo** (`modules/profiles/common.nix`): accepted
  fleet-wide; SSH access is hardware-key-only and interactive logins are
  already strongly authenticated.
- **Nix-managed authorized keys only**: the srvos modules force
  `authorizedKeysFiles` to `/etc/ssh/authorized_keys.d/%u`, so
  `~/.ssh/authorized_keys` is ignored on every host. New keys must be added
  through the users modules — remember this during recovery.
- **Unencrypted disks on arcadia/argus**: stationary machines; they hold
  nebula/wireguard credentials and the host age identity, so physical theft
  implies overlay-credential rotation (minerva uses LUKS).
- **fail2ban ignores the nebula overlay** (`10.99.99.0/24`) so a typo'd
  password can never lock out overlay SSH — the escalating bans apply to
  everyone else.
