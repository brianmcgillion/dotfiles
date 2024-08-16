# SPDX-License-Identifier: Apache-2.0
{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosModules = {
    # shared modules
    common-client = import ./common-client.nix;
    common-server = import ./common-server.nix;

    # host modules
    host-arcadia = import ./arcadia;
    host-minerva = import ./minerva { inherit self inputs lib; };
    host-nephele = import ./nephele;
    host-caelus = import ./caelus;
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

      minerva = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-minerva ];
      };

      nephele = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-nephele ];
      };

      caelus = lib.nixosSystem {
        inherit specialArgs;
        modules = [ self.nixosModules.host-caelus ];
      };
    };
}
