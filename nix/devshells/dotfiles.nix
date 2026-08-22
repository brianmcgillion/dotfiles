# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# devShells.default - the environment for working *on* this repository.
# Portable per-language shells live alongside this file; see ./names.nix.
{
  lib,
  self,
  ...
}:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Reads only hostname/sshUser/sshOpts, never profiles.system.path: that
      # evaluates the deploy-rs activation derivation, which would drag a full
      # nixosConfiguration eval into every `nix develop`.
      nodeSshCase = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: node:
          "    ${name}) ssh ${lib.escapeShellArgs node.profiles.system.sshOpts} ${node.profiles.system.sshUser}@${node.hostname} \"$@\" ;;"
        ) self.deploy.nodes
      );

      reboot-nodes = pkgs.writeShellApplication {
        name = "reboot-nodes";
        runtimeInputs = [ pkgs.openssh ];
        text = ''
          REBOOT_NODES=${lib.escapeShellArg (lib.concatStringsSep " " (lib.attrNames self.deploy.nodes))}
          readonly REBOOT_NODES

          node_ssh() {
            local node=$1
            shift
            case "$node" in
          ${nodeSshCase}
              *)
                echo "reboot-nodes: unknown node '$node'" >&2
                return 2
                ;;
            esac
          }
        ''
        + builtins.readFile "${self}/packages/scripts/reboot-nodes.sh";
      };
    in
    {
      devshells.default = {
        devshell = {
          name = "dotfiles-devshell";
          meta.description = "NixOS dotfiles development environment";
          packages = [
            # keep-sorted start
            config.treefmt.build.wrapper
            pkgs.cachix
            pkgs.deploy-rs
            pkgs.nebula # nebula-cert, used by scripts/nebula-add-device.sh
            pkgs.nix-eval-jobs
            pkgs.nix-fast-build
            pkgs.nix-output-monitor
            pkgs.nix-tree
            pkgs.nixVersions.latest
            pkgs.reuse
            pkgs.sops
            pkgs.ssh-to-age
            # keep-sorted end
          ]
          ++ lib.attrValues config.treefmt.build.programs;
        };

        devshell.startup.pre-commit-hooks.text = config.pre-commit.installationScript;

        commands = [
          {
            category = "development";
            name = "build-devshells";
            help = "Build every portable devshell (c-cpp, embedded, go, python, reverse-engineering, rust)";
            # Deliberately not wired into `nix flake check`: that runs on every
            # push and in the normal local workflow, and building ghidra + a
            # Rust toolchain + an ARM cross-compiler there would dwarf the
            # existing dry-run-only CI. Build them on demand instead.
            # --no-link: without it nix-fast-build litters the repo root with a
            # result-<shell> symlink per devshell.
            command = ''
              ${pkgs.nix-fast-build}/bin/nix-fast-build --no-link \
                --flake ".#devShells.${pkgs.stdenv.hostPlatform.system}" "$@"
            '';
          }
          {
            category = "setup";
            name = "setup-netrc";
            help = "Extract netrc credentials from SOPS secrets to ~/.netrc";
            command = ''
              exec ${pkgs.writeScriptBin "setup-netrc" (builtins.readFile "${self}/packages/scripts/setup-netrc.sh")}/bin/setup-netrc "$@"
            '';
          }
          {
            category = "development";
            name = "sync-binaryninja";
            help = "Re-pin the local Binary Ninja zip and stage it into the Nix store";
            command = ''
              exec ${pkgs.writeScriptBin "sync-binaryninja" (builtins.readFile "${self}/packages/scripts/sync-binaryninja.sh")}/bin/sync-binaryninja "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-hetzner-server";
            help = "Deploy NixOS to Hetzner servers (nubes, caelus)";
            command = ''
              exec ${pkgs.writeScriptBin "deploy-hetzner-server" (builtins.readFile "${self}/packages/scripts/deploy-hetzner-server.sh")}/bin/deploy-hetzner-server "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-rs";
            help = "Deploy with deploy-rs to configured nodes";
            command = ''
              ${pkgs.deploy-rs}/bin/deploy "$@"
            '';
          }
          {
            category = "deployment";
            name = "reboot-nodes";
            help = "Reboot the deploy-rs nodes whose kernel/initrd changed";
            command = ''
              exec ${reboot-nodes}/bin/reboot-nodes "$@"
            '';
          }
        ]
        # One deploy-<node> per deploy-rs target, so the list here cannot drift
        # from nix/deployments.nix -- which it had, deploy-argus having outlived
        # the commented-out argus node.
        ++ lib.mapAttrsToList (name: _: {
          category = "deployment";
          name = "deploy-${name}";
          help = "Deploy to ${name} (skips flake checks)";
          command = ''
            ${pkgs.deploy-rs}/bin/deploy --skip-checks ".#${name}" "$@"
          '';
        }) self.deploy.nodes;
      };
    };
}
