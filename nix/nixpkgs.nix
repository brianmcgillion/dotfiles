# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ lib, inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      # customise pkgs
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system inputs;
        config.allowUnfree = true;
      };

      # make custom top-level lib available to all `perSystem` functions
      _module.args.lib = lib;
    };
}
