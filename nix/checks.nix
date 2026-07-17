# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];
  perSystem =
    {
      config,
      pkgs,
      self',
      lib,
      ...
    }:
    {
      # git-hooks.nix auto-adds checks.pre-commit, which runs every enabled
      # hook over all files. Hooks must not be restricted to the pre-push
      # stage: staged hooks are skipped by that check, turning it into a
      # green no-op (and reuse/whitespace would then only ever run locally).
      checks = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;

      pre-commit = {
        settings = {
          hooks = {
            treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
            reuse = {
              enable = true;
              package = pkgs.reuse;
            };
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
      };
    };
}
