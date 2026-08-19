# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Go toolchain. Entered from anywhere with `dev go`.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.go = {
        devshell = {
          name = "go";
          meta.description = "Go toolchain: go, gopls, delve, golangci-lint";
          packages = [
            # keep-sorted start
            pkgs.delve
            pkgs.go
            pkgs.go-tools
            pkgs.gofumpt
            pkgs.golangci-lint
            pkgs.gopls
            pkgs.gotools
            # keep-sorted end
          ];
        };

        # No GOPATH override on purpose. Pointing it at $PRJ_DATA_DIR would
        # create a .data/ directory in whatever folder `dev go` is run from,
        # and there is no host Go install to isolate from (go is not in
        # home/development/base-system.nix), so the default ~/go is both less
        # surprising and shares the module cache across projects.
      };
    };
}
