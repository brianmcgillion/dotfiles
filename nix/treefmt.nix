# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-root.flakeModule
    inputs.treefmt-nix.flakeModule
  ];
  perSystem =
    { config, pkgs, ... }:
    {
      treefmt.config = {
        inherit (config.flake-root) projectRootFile;

        programs = {
          # Nix standard formatter according to RFC 166 (https://github.com/NixOS/rfcs/pull/166)
          nixfmt.enable = true;
          # Remove dead Nix code (https://github.com/astro/deadnix)
          deadnix.enable = true;
          # Prevent use of Nix anti-patterns (https://github.com/nerdypepper/statix)
          statix.enable = true;
          # Nix diagnostics with auto-fix
          nixf-diagnose.enable = true;
          # Lint shell scripts (https://github.com/koalaman/shellcheck)
          shellcheck.enable = true;
          # Shell formatting best practices
          shfmt.enable = true;
          # Maintain sorted lists
          keep-sorted.enable = true;
        };

        settings.formatter = {
          statix-check = {
            # Statix doesn't support multiple file targets, so we wrap it.
            # Accumulate the exit status: a bare loop would return only the
            # last file's status, silently swallowing findings in every
            # other file of the batch.
            command = pkgs.writeShellScriptBin "statix-check" ''
              rc=0
              for file in "''$@"; do
                ${lib.getExe pkgs.statix} check "$file" || rc=1
              done
              exit $rc
            '';
            options = [ ];
            includes = [ "*.nix" ];
          };

          nixf-diagnose = {
            # Ensure nixfmt cleans up after nixf-diagnose.
            priority = -1;
            # Note: --auto-fix is already enabled by default via programs.nixf-diagnose.autoFix
            # Rule names can currently be looked up here:
            # https://github.com/nix-community/nixd/blob/main/libnixf/src/Basic/diagnostic.py
          };
        };
      };
    };
}
