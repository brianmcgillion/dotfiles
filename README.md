
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

