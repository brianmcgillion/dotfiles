
## Introduction

Flake based nixos configuration. Intended as a private config, so it is not abstracted to bootstrap any other system than my own.

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
