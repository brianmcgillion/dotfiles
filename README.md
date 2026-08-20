
## Introduction

Flake based nixos configuration. Intended as a private config, so it is not abstracted to bootstrap any other system than my own.

## Development shells

`dev` is on `$PATH` on every host and works from any directory, not just this checkout:

```sh
dev list          # c-cpp, embedded, go, python, reverse-engineering, rust
dev rust          # enter one
dev init rust     # or drop an .envrc so direnv loads it on cd
dev tmp rust      # ephemeral .envrc, removed when the shell exits

dev c-cpp,reverse-engineering   # stack shells - works with init/tmp/forget/update too
```

Stacks *layer* rather than merge: each shell is entered inside the previous one (or gets its own
`use flake` line), so later entries win on `PATH` and every shell's environment variables survive.
Merging would not work — devshell composes packages with `pkgs.buildEnv`, and e.g. `c-cpp`'s
clang-wrapper and `reverse-engineering`'s binutils both ship `bin/ld.gold`.

`dev tmp` exists because a daemonised editor never sees `dev rust` — Emacs picks a toolchain up
only from an `.envrc` on disk. It gives you one without leaving a file behind in someone else's
repo.

Shells are defined in `nix/devshells/` and each is kept in its own Nix profile, so it survives
garbage collection and re-entry is instant. See CLAUDE.md for the full command set.

## Setup

### Servers (Hetzner)

Provisioning is automated via nixos-anywhere and a kexec installer:

```sh
nix develop -c deploy-hetzner-server <hostname>
```

The script loads the installer, extracts the host's age key, re-encrypts the
sops secrets, and installs the configuration (see
`packages/scripts/deploy-hetzner-server.sh`).

### Desktops / laptops (manual install)

1. Acquire a NixOS installer image:
   ```sh
   # download nixos-unstable
   wget -O nixos.iso https://channels.nixos.org/nixos-unstable/latest-gnome-minimal-x86_64-linux.iso

   # Write to usb drive
   cp nixos.iso /dev/sdX
   ```

2. Boot the installer.

3. Define partitions and mount your root to `/mnt`.

4. Install this config:
   ```sh
   nix-shell -p git nix

   git clone https://github.com/brianmcgillion/dotfiles /etc/dotfiles
   cd /etc/dotfiles

   # Set HOST: the hostname for the new system
   HOST=...

   # Create the host config and add it to the repo:
   mkdir -p hosts/$HOST
   nixos-generate-config --root /mnt --dir /etc/dotfiles/hosts/$HOST
   rm -f hosts/$HOST/configuration.nix

   # Merge the generated hardware config into hosts/$HOST/default.nix,
   # import a profile (profile-client or profile-server) and enable features.
   nano hosts/$HOST/default.nix

   # Register the host in hosts/default.nix: add host-$HOST to
   # flake.nixosModules and $HOST to the genAttrs host list.
   nano hosts/default.nix

   git add hosts/$HOST hosts/default.nix

   # Install NixOS
   nixos-install --flake ".#$HOST" --extra-experimental-features 'nix-command flakes'

   # Then move the dotfiles to the mounted drive!
   mv /etc/dotfiles /mnt/etc/dotfiles
   ```

5. Then reboot to a built system.

See ARCHITECTURE.md for the full "Adding a New Host" walkthrough.

## Update

    nix flake update
    sudo nixos-rebuild switch --flake .#MACHINE_NAME
