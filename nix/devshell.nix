# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, lib, ... }:
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
          ]
          ++ lib.attrValues config.treefmt.build.programs;
        };

        commands = [ ];
      };
    };
}
