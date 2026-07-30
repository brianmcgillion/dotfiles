# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Helper scripts (writeShellApplication: shebang + set -euo pipefail +
# build-time shellcheck; a failed cd aborts instead of running nix commands
# against the wrong directory).
{ lib, pkgs, ... }:
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
  # Ghaf board rebuilds: `nixos-rebuild boot` over SSH against a running
  # ghaf-host. Deliberately no `cd` — unlike rebuild-host/-nubes/-caelus these
  # act on the ghaf checkout you are standing in, not on ~/.dotfiles.
  #
  # GHAF_HOST overrides the target host at runtime (a differently-named or
  # bare-IP host no longer needs its own wrapper), GHAF_ACTION the rebuild
  # action (`boot` is hardcoded before "$@" otherwise, so `switch` would be
  # rejected as an unknown positional).
  mkGhafRebuild =
    name: flake: host:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        nixos-rebuild --flake ".#${flake}" \
          --target-host "root@''${GHAF_HOST:-${host}}" \
          --no-reexec "''${GHAF_ACTION:-boot}" "$@"
      '';
    };

  # Every board gets both wrappers: rebuild-<board> against <host> and
  # rebuild-<board>-usb against <host>-usb, for boards booted off external
  # media.
  mkGhafRebuilds =
    name:
    {
      flake,
      host ? "ghaf-host",
    }:
    [
      (mkGhafRebuild "rebuild-${name}" flake host)
      (mkGhafRebuild "rebuild-${name}-usb" flake "${host}-usb")
    ];

  ghafTargets = {
    # keep-sorted start block=yes
    agx = {
      flake = "nvidia-jetson-orin-agx-debug-from-x86_64";
      host = "agx-host";
    };
    alien.flake = "alienware-m18-debug";
    darter.flake = "system76-darp11-b-debug";
    ghaf.flake = "intel-laptop-debug";
    x1.flake = "lenovo-x1-carbon-gen11-debug";
    # keep-sorted end
  };

  ghafRebuilds = lib.concatLists (lib.mapAttrsToList mkGhafRebuilds ghafTargets);

  deploy-hetzner-server = pkgs.writeShellApplication {
    name = "deploy-hetzner-server";
    text = builtins.readFile ./deploy-hetzner-server.sh;
  };
in
{
  environment.systemPackages = [
    # keep-sorted start
    deploy-hetzner-server
    rebuild-caelus
    rebuild-host
    rebuild-nubes
    sync-binaryninja
    update-host
    # keep-sorted end
  ]
  # rebuild-{agx,alien,darter,ghaf,x1} plus a -usb variant of each
  ++ ghafRebuilds;
}
