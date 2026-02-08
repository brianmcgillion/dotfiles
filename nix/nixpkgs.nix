# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  inputs,
  self,
  ...
}:
{
  perSystem =
    { system, ... }:
    {
      # Customize pkgs with unfree packages allowed and custom overlays
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.own-pkgs-overlay ];
      };

      # make custom top-level lib available to all `perSystem` functions
      _module.args.lib = lib;
    };
}
