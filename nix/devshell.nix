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
          name = "Systems devshell";
          meta.description = "Systems development environment";
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
            #inputs'.deploy-rs.packages.default
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
