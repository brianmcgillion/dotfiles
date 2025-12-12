# Features Matrix

Overview of which features are enabled on each host.

## Legend
- ✓ Enabled by default (from profile)
- ✗ Explicitly enabled in host config
- ○ Available but not enabled
- ― Not applicable

## Desktop Features

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| Audio (PipeWire) | ✓ | ✓ | ― | ― |
| Desktop Manager (GNOME) | ✓ | ✓ | ― | ― |
| YubiKey Support | ✓ | ✓ | ― | ― |

## Development Features

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| Emacs (Doom) | ✓ | ✓ | ― | ― |
| Emacs UI Tools | ✓ | ✓ | ― | ― |

## Networking Features

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| Nebula Network | ✗ | ✗ | ✗ | ✗ (lighthouse) |
| WireGuard | ✗ | ✗ | ○ | ○ |

## Security Features

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| System Hardening | ✓ | ✓ | ✓ | ✓ |
| SSH Server | ✓ | ✗ | ✓ | ✓ |
| Fail2ban | ○ | ○ | ✓ | ✓ |

## System Features

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| System Packages | ✓ | ✓ | ✓ | ✓ |
| XDG Compliance | ✓ | ✓ | ✓ | ✓ |
| Locale & Fonts | ✓ | ✓ | ― | ― |

## Hardware

| Feature | arcadia | minerva | nubes | caelus |
|---------|---------|---------|---------|--------|
| NVIDIA GPU | ✗ | ― | ― | ― |
| Intel CPU | ― | ✓ | ― | ✓ |
| AMD CPU | ✓ | ― | ✓ | ― |
| Disk Encryption | ― | ✓ | ― | ― |
| Disko Management | ― | ― | ✓ | ✓ |

## Profiles

| Host | Profile | Type |
|------|---------|------|
| arcadia | client | Desktop workstation |
| minerva | client | Laptop |
| nubes | server | Dedicated server |
| caelus | server | Cloud server |

## Feature Enabling Patterns

### Default from Profile
Features marked with ✓ are enabled by default through the profile import:
```nix
imports = [ self.nixosModules.profile-client ];
# Automatically enables: audio, desktop-manager, emacs, yubikey, locale-fonts
```

### Explicit Enable
Features marked with ✗ require explicit configuration:
```nix
features.networking.nebula = {
  enable = true;
  # ... configuration
};
```

### Override Default
To disable a default feature:
```nix
features.desktop.audio.enable = lib.mkForce false;
```

## Adding Features

To enable a feature on a host, add to its configuration:
```nix
features.<category>.<feature>.enable = true;
```

To add a new feature to all hosts of a type, add to the profile:
```nix
# In modules/profiles/client.nix
imports = [ self.nixosModules.feature-new-thing ];
config.features.<category>.new-thing.enable = lib.mkDefault true;
```
