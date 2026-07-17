# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
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
    };
}
