# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Helper scripts (writeShellApplication: shebang + set -euo pipefail +
# build-time shellcheck; a failed cd aborts instead of running nix commands
# against the wrong directory).
{
  lib,
  pkgs,
  self,
  ...
}:
let
  # Portable devshell names. Imported as a parse-time relative path on purpose:
  # reading them off self.devShells.<system> instead would drag the whole
  # flake-parts perSystem evaluation (treefmt, git-hooks, devshell module) into
  # every nixos-rebuild just to list five strings.
  devShellNames = import ../../nix/devshells/names.nix;

  # Where the Nextcloud sync (home/apps/nextcloud.nix) drops vendor installers.
  vendorBinariesDir = "$HOME/Documents/binaries";
  vendorBinaries = lib.importJSON ../../modules/profiles/vendor-binaries.json;

  dev-unwrapped = pkgs.writeShellApplication {
    name = "dev";
    text = ''
      DEV_SHELLS="${lib.concatStringsSep " " devShellNames}"
      DEV_FLAKE_FALLBACK="${self}"
      export DEV_SHELLS DEV_FLAKE_FALLBACK
    ''
    + builtins.readFile ./dev.sh;
  };

  dev-completion = pkgs.writeTextFile {
    name = "dev-bash-completion";
    destination = "/share/bash-completion/completions/dev";
    text = ''
      complete -W "${
        lib.concatStringsSep " " (
          devShellNames
          ++ [
            "list"
            "init"
            "tmp"
            "forget"
            "update"
          ]
        )
      }" dev
    '';
  };

  # Ship the completion in the same derivation as the binary so the two can
  # never drift apart in environment.systemPackages.
  dev = pkgs.symlinkJoin {
    name = "dev";
    paths = [
      dev-unwrapped
      dev-completion
    ];
  };

  # Records the synced vendor installers in vendor-binaries.json and stages them.
  sync-vendor-binaries = pkgs.writeShellApplication {
    name = "sync-vendor-binaries";
    runtimeInputs = [ pkgs.nix ];
    text = builtins.readFile ./sync-vendor-binaries.sh;
  };

  update-host = pkgs.writeShellApplication {
    name = "update-host";
    runtimeInputs = [ sync-vendor-binaries ];
    text = ''
      cd "$HOME/.dotfiles"
      nix flake update

      if [ -d "''${VENDOR_BINARIES:-${vendorBinariesDir}}" ]; then
        sync-vendor-binaries
      else
        # Not fatal: update-host's job is the flake update, and the installers
        # are out-of-tree so they may legitimately be absent right now.
        echo "update-host: no ${vendorBinariesDir} -- skipping sync-vendor-binaries" >&2
      fi
    '';
  };

  rebuild-host = pkgs.writeShellApplication {
    name = "rebuild-host";
    runtimeInputs = [ pkgs.nix ];
    text =
      # seclab-pkgs' requireFile only looks in the store, so an installer that
      # merely exists in ~/Documents fails the build until it is staged.
      lib.concatMapStrings (artifact: ''
        file="''${VENDOR_BINARIES:-${vendorBinariesDir}}/${artifact.path}"
        staged="$(nix-store --print-fixed-path sha256 \
          "${artifact.sha256}" "${baseNameOf artifact.path}")"
        if [ ! -e "$staged" ] && [ -f "$file" ]; then
          nix-store --add-fixed sha256 "$file" >/dev/null
        fi
      '') (lib.attrValues vendorBinaries)
      + ''
        cd "$HOME/.dotfiles"
        sudo nixos-rebuild switch --flake ".#$HOSTNAME" "$@"
      '';
  };

  # One rebuild-<node> per deploy-rs target, generated from self.deploy.nodes
  # (nix/deployments.nix) so the host, ssh user and ssh options can never drift
  # from what deploy-rs itself uses -- adding a node there is all it takes..
  mkDeployRebuild =
    name: node:
    let
      # Not named `system`: that reads as a platform string in Nix.
      target = node.profiles.system;
    in
    pkgs.writeShellApplication {
      name = "rebuild-${name}";
      text = ''
        cd "$HOME/.dotfiles"
        # nixos-rebuild word-splits NIX_SSHOPTS, so the options are joined into
        # one string rather than quoted individually.
        export NIX_SSHOPTS=${lib.escapeShellArg (lib.concatStringsSep " " target.sshOpts)}
        nixos-rebuild "''${REBUILD_ACTION:-switch}" --flake ".#${name}" \
          --target-host "${target.sshUser}@${node.hostname}" "$@"
      '';
    };

  deployRebuilds = lib.mapAttrsToList mkDeployRebuild self.deploy.nodes;
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
    dev
    rebuild-host
    sync-vendor-binaries
    update-host
    # keep-sorted end
  ]
  # rebuild-{agx,alien,darter,ghaf,x1} plus a -usb variant of each
  ++ ghafRebuilds
  # rebuild-<node> for every deploy-rs target in nix/deployments.nix
  ++ deployRebuilds;
}
