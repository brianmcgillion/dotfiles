# SPDX-License-Identifier: Apache-2.0
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
          # nix standard formatter according to rfc 166 (https://github.com/NixOS/rfcs/pull/166)
          nixfmt.enable = true;
          nixfmt.package = pkgs.nixfmt-rfc-style;
          deadnix.enable = true; # removes dead nix code https://github.com/astro/deadnix
          statix.enable = true; # prevents use of nix anti-patterns https://github.com/nerdypepper/statix
          shellcheck.enable = true; # lints shell scripts https://github.com/koalaman/shellcheck
          shfmt.enable = true; # Shell formatting best practices
        };

        settings.formatter.statix-check = {
          # statix doesn't support multiple file targets
          command = pkgs.writeShellScriptBin "statix-check" ''
            for file in "''$@"; do
              ${lib.getExe pkgs.statix} check "$file"
            done
          '';
          options = [ ];
          includes = [ "*.nix" ];
        };
      };

      formatter = config.treefmt.build.wrapper;
    };
}
