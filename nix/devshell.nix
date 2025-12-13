# SPDX-License-Identifier: Apache-2.0
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
      inputs',
      ...
    }:
    {
      devshells.default = {
        devshell = {
          name = "dotfiles-devshell";
          meta.description = "NixOS dotfiles development environment";
          packages = [
            pkgs.cachix
            pkgs.nix-eval-jobs
            pkgs.nix-fast-build
            pkgs.nix-output-monitor
            pkgs.nix-tree
            pkgs.nixVersions.latest
            pkgs.sops
            pkgs.ssh-to-age
            pkgs.reuse
            config.treefmt.build.wrapper
            inputs'.deploy-rs.packages.default
          ]
          ++ lib.attrValues config.treefmt.build.programs;
        };

        devshell.startup.pre-commit-hooks.text = config.pre-commit.installationScript;

        commands = [
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
              ${inputs'.deploy-rs.packages.default}/bin/deploy "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-caelus";
            help = "Deploy to caelus server (skips flake checks)";
            command = ''
              ${inputs'.deploy-rs.packages.default}/bin/deploy --skip-checks .#caelus "$@"
            '';
          }
          {
            category = "deployment";
            name = "deploy-nubes";
            help = "Deploy to nubes server (skips flake checks)";
            command = ''
              ${inputs'.deploy-rs.packages.default}/bin/deploy --skip-checks .#nubes "$@"
            '';
          }
        ];
      };
    };
}
