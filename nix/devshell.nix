# SPDX-License-Identifier: Apache-2.0
{ inputs, lib, ... }:
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
          name = "Systems devshell";
          meta.description = "Systems development environment";
          packages =
            builtins.attrValues {
              inherit (pkgs)
                git
                nix
                nixos-rebuild
                #TODO Reenable
                #sops-nix
                sops
                ssh-to-age
                deploy-rs
                ;
            }
            ++ [
              inputs'.nix-fast-build.packages.default
              config.treefmt.build.wrapper
            ]
            ++ lib.attrValues config.treefmt.build.programs;
        };

        commands = [
          # {
          #   help = "Check golang vulnerabilities";
          #   name = "go-checksec";
          #   command = "gosec ./...";
          # }
          # {
          #   help = "Update go dependencies";
          #   name = "go-update";
          #   command = "go get -u ./... && go mod tidy && go mod vendor";
          # }
          # {
          #   help = "golang linter";
          #   package = "golangci-lint";
          #   category = "linters";
          # }
        ];
      };
    };
}
