# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosModules = {
    # host modules
    host-arcadia = import ./arcadia;
    host-argus = import ./argus;
    host-minerva = import ./minerva;
    host-caelus = import ./caelus;
    host-nubes = import ./nubes;
  };

  flake.nixosConfigurations =
    let
      # make self and inputs available in nixos modules
      specialArgs = {
        inherit self inputs;
      };
    in
    {
      arcadia = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-arcadia ];
      };

      argus = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-argus ];
      };

      minerva = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-minerva ];
      };

      caelus = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-caelus ];
      };

      nubes = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-nubes ];
      };

    };
}
