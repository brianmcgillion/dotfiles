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
                nixos-rebuild
                sops
                ssh-to-age
                ;
            }
            ++ [
              inputs'.nix-fast-build.packages.default
              config.treefmt.build.wrapper
              inputs'.deploy-rs.packages.default
              pkgs.nixVersions.latest
            ]
            ++ lib.attrValues config.treefmt.build.programs;
        };

        commands = [
          #TODO update the sops keys for all hosts
          #sops updatekeys secrets/example.yaml

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
