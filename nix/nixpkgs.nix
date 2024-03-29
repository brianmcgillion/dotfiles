# SPDX-License-Identifier: Apache-2.0
{
  lib,
  inputs,
  ...
}: {
  perSystem = {system, ...}: {
    # customise pkgs
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system inputs;
      overlays = [inputs.nixd.overlays.default];
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "nix-2.16.2"
      ];
    };

    # make custom top-level lib available to all `perSystem` functions
    _module.args.lib = lib;
  };
}
