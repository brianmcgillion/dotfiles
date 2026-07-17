# Features Matrix

Overview of which features are enabled on each host.

> Maintained by hand — when adding a feature or host, update this file
> (`modules/profiles/*.nix` and `hosts/*/default.nix` are the source of truth).

## Legend
- ✓ Enabled by default (from profile)
- ✗ Explicitly enabled in host config
- ○ Available but not enabled
- ― Not applicable (module not imported)

## AI Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| Ollama (LLM inference) | ○ | ○ | ✗ | ― | ― |

## Desktop Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| Audio (PipeWire) | ✓ | ✓ | ✓ | ― | ― |
| Desktop Manager (GNOME) | ✓ | ✓ | ✓ | ― | ― |
| Power Management (SSH-aware) | ✓ | ✓ | ✓ | ― | ― |
| keyd (per-device remapping) | ○ | ✗ | ○ | ― | ― |
| YubiKey Support | ✓ | ✓ | ✓ | ― | ― |

## Development Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| Emacs (Doom) | ✓ | ✓ | ✓ | ― | ― |
| Emacs UI Tools | ✓ | ✓ | ✓ | ― | ― |
| Docker | ✓ | ✓ | ✓ | ― | ― |
| Binary Ninja | ○ | ✗ | ○ | ― | ― |
| GreatFET | ✓ | ✓ | ✓ | ― | ― |
| reMarkable sync | ✓ | ✓ | ✓ | ― | ― |
| Saleae Logic | ✓ | ✓ | ✓ | ― | ― |
| STM32CubeProgrammer | ○ | ✗ | ○ | ― | ― |
| UniFlash (TI) | ○ | ✗ | ○ | ― | ― |
| C2000 codegen tools (TI) | ○ | ✗ | ○ | ― | ― |

## Networking Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| Nebula Network | ✗ | ✗ | ✗ | ✗ | ✗ (lighthouse) |
| WireGuard (wg0 → bmg-vps) | ✗ | ✗ | ✗ | ― | ― |

## Security Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| System Hardening | ✓ | ✓ | ✓ | ✓ | ✓ |
| SSH Server (hardened sshd) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Fail2ban | ✓ | ✓ | ✓ | ✓ | ✓ |

Fail2ban is auto-enabled by the sshd feature on every host that runs SSH.

## System Features

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| System Packages | ✓ | ✓ | ✓ | ✓ | ✓ |
| XDG Compliance | ✓ | ✓ | ✓ | ✓ | ✓ |
| Locale & Fonts | ✓ | ✓ | ✓ | ― | ― |
| GitHub token (nix rate limits) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Remote builders | ✓ | ✓ | ✓ | ○ | ○ |

## Hardware

| Feature | arcadia | minerva | argus | nubes | caelus |
|---------|---------|---------|-------|-------|--------|
| NVIDIA GPU | ✗ | ― | ✗ | ― | ― |
| CPU | AMD | Intel | AMD | AMD | Intel (virt.) |

## Profiles

| Host | Profile | Type |
|------|---------|------|
| arcadia | client | Desktop |
| argus | client | ML Desktop |
| minerva | client | Laptop |
| nubes | server | Dedicated server |
| caelus | server | Cloud server |

## Feature Enabling Patterns

### Default from Profile
Features marked with ✓ are enabled by default through the profile import:
```nix
imports = [ self.nixosModules.profile-client ];
# Automatically enables: audio, desktop-manager, power-management, yubikey,
# sshd, docker, emacs, emacs-ui, greatfet, remarkable, saleae-logic,
# locale-fonts, remote-builders
```

### Explicit Enable
Features marked with ✗ require explicit configuration:
```nix
features.networking.nebula = {
  enable = true;
  useSopsSecrets = true;
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
