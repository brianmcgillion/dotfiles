# Suggested Commands

## System Scripts (available system-wide after rebuild)
These scripts are installed to `environment.systemPackages` and available globally:

| Command | Description |
|---------|-------------|
| `rebuild-host` | Rebuild current host: `sudo nixos-rebuild switch --flake .#$HOSTNAME` |
| `update-host` | Update flake inputs: `nix flake update` |
| `rebuild-nubes` | Deploy to nubes server via SSH |
| `rebuild-caelus` | Deploy to caelus server via SSH |
| `deploy-hetzner-server` | Provision new Hetzner server with nixos-anywhere |

## Development Shell Commands
Enter devshell first: `nix develop`

| Command | Description |
|---------|-------------|
| `deploy-rs` | Deploy with deploy-rs to configured nodes |
| `deploy-caelus` | Deploy to caelus (skips flake checks) |
| `deploy-nubes` | Deploy to nubes (skips flake checks) |

## Formatting and Linting
```bash
nix fmt                        # Format all files with treefmt
nix fmt -- --fail-on-change    # Check formatting without changes
nix develop --command reuse lint  # Check REUSE license compliance
```

## Building and Testing
```bash
nix flake check                # Run all checks (pre-commit, treefmt, deploy validation)
nix flake show --all-systems   # Show all flake outputs
nixos-rebuild dry-run --flake .#HOSTNAME   # Dry-run build (fast)
nixos-rebuild dry-activate --flake .#HOSTNAME  # Build and show activation script
nixos-rebuild build --flake .#HOSTNAME     # Full build
```

## Remote Deployment
```bash
# Using nixos-rebuild (builds locally, activates remotely)
nixos-rebuild switch --flake .#nubes --target-host "root@nubes"
nixos-rebuild switch --flake .#caelus --target-host "root@caelus"

# Using deploy-rs (from devshell)
deploy-rs .#caelus
deploy-rs .#nubes
```

## Secrets Management
```bash
sops secrets.yaml              # Edit global secrets
sops modules/users/brian/bmg-secrets.yaml  # Edit user secrets
sops hosts/caelus/secrets.yaml # Edit host-specific secrets
```

## Flake Inputs
```bash
nix flake update               # Update all inputs
nix flake update nixpkgs       # Update single input
nix flake lock --update-input home-manager  # Alternative syntax
```

## Evaluation and Debugging
```bash
nix eval .#nixosModules --apply 'x: builtins.attrNames x'  # List NixOS modules
nix eval .#homeModules --apply 'x: builtins.attrNames x'   # List home-manager modules
nix repl --expr 'builtins.getFlake (toString ./.)'         # Interactive REPL
```
