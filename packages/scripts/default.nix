# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Helper scripts (writeShellApplication: shebang + set -euo pipefail +
# build-time shellcheck; a failed cd aborts instead of running nix commands
# against the wrong directory).
{ pkgs, ... }:
let
  sync-binaryninja = pkgs.writeShellApplication {
    name = "sync-binaryninja";
    text = builtins.readFile ./sync-binaryninja.sh;
  };
  update-host = pkgs.writeShellApplication {
    name = "update-host";
    text = ''
      cd "$HOME/.dotfiles"
      nix flake update
      # Re-pin the Binary Ninja zip only on hosts that actually have it; skipping
      # keeps `update-host` working on hosts without the out-of-tree zip.
      if [ -f "''${BINARYNINJA_ZIP:-$HOME/projects/tools/binaryninja/binaryninja_linux_dev_ultimate.zip}" ]; then
        ${sync-binaryninja}/bin/sync-binaryninja
      fi
    '';
  };
  rebuild-host = pkgs.writeShellApplication {
    name = "rebuild-host";
    text = ''
      cd "$HOME/.dotfiles"
      sudo nixos-rebuild switch --flake ".#$HOSTNAME" "$@"
    '';
  };
  rebuild-nubes = pkgs.writeShellApplication {
    name = "rebuild-nubes";
    text = ''
      cd "$HOME/.dotfiles"
      nixos-rebuild switch --flake .#nubes --target-host "root@nubes" "$@"
    '';
  };
  rebuild-caelus = pkgs.writeShellApplication {
    name = "rebuild-caelus";
    text = ''
      cd "$HOME/.dotfiles"
      nixos-rebuild switch --flake .#caelus --target-host "root@caelus" "$@"
    '';
  };
  rebuild-x1 = pkgs.writeShellApplication {
    name = "rebuild-x1";
    text = ''
      nixos-rebuild --flake .#lenovo-x1-carbon-gen11-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
    '';
  };
  rebuild-alien = pkgs.writeShellApplication {
    name = "rebuild-alien";
    text = ''
      nixos-rebuild --flake .#alienware-m18-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
    '';
  };
  rebuild-agx = pkgs.writeShellApplication {
    name = "rebuild-agx";
    text = ''
      nixos-rebuild --flake .#nvidia-jetson-orin-agx-debug-from-x86_64 --target-host "root@agx-host" --no-reexec boot "$@"
    '';
  };
  rebuild-darter = pkgs.writeShellApplication {
    name = "rebuild-darter";
    text = ''
      nixos-rebuild --flake .#system76-darp11-b-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
    '';
  };
  rebuild-darter-usb = pkgs.writeShellApplication {
    name = "rebuild-darter-usb";
    text = ''
      nixos-rebuild --flake .#system76-darp11-b-debug --target-host "root@ghaf-host-usb" --no-reexec boot "$@"
    '';
  };
  deploy-hetzner-server = pkgs.writeShellApplication {
    name = "deploy-hetzner-server";
    text = builtins.readFile ./deploy-hetzner-server.sh;
  };
in
{
  environment.systemPackages = [
    # keep-sorted start
    deploy-hetzner-server
    rebuild-agx
    rebuild-alien
    rebuild-caelus
    rebuild-darter
    rebuild-darter-usb
    rebuild-host
    rebuild-nubes
    rebuild-x1
    sync-binaryninja
    update-host
    # keep-sorted end
  ];
}
