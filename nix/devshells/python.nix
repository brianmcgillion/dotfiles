# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Python toolchain. Entered from anywhere with `dev python`.
#
# uv owns virtualenvs and dependency resolution; this shell only supplies the
# interpreter and the static tooling. Note that `uv` is already in the global
# home profile (home/development/base-system.nix) - it is repeated here so the
# shell stands on its own on hosts that do not install that profile.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.python = {
        devshell = {
          name = "python";
          meta.description = "Python toolchain: uv, ruff, ty, pyright";
          packages = [
            # keep-sorted start
            pkgs.pyright
            pkgs.python3
            pkgs.python3Packages.ipython
            pkgs.ruff
            pkgs.ty
            pkgs.uv
            # keep-sorted end
          ];
        };

        env = [
          # Stop uv from silently downloading its own interpreter behind the
          # one Nix just provided.
          {
            name = "UV_PYTHON_DOWNLOADS";
            value = "never";
          }
          {
            name = "UV_PYTHON";
            value = "${pkgs.python3}/bin/python3";
          }
        ];
      };
    };
}
