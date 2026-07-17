# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [ inputs.devshell.flakeModule ];
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
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
            name = "deploy-argus";
            help = "Deploy to argus (skips flake checks)";
            command = ''
              ${pkgs.deploy-rs}/bin/deploy --skip-checks .#argus "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-caelus";
            help = "Deploy to caelus server (skips flake checks)";
            command = ''
              ${pkgs.deploy-rs}/bin/deploy --skip-checks .#caelus "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-nubes";
            help = "Deploy to nubes server (skips flake checks)";
            command = ''
              ${pkgs.deploy-rs}/bin/deploy --skip-checks .#nubes "$@"
            '';
          }
        ];
      };
    };
}
