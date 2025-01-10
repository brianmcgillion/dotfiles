# SPDX-License-Identifier: Apache-2.0
{ lib, inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      # customise pkgs
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system inputs;
        config.allowUnfree = true;
        overlays = [ inputs.emacs-overlay.overlays.default ];
      };

      # make custom top-level lib available to all `perSystem` functions
      _module.args.lib = lib;
    };
}
