# SPDX-License-Identifier: Apache-2.0
{
  inputs,
  self,
  lib,
  ...
}: {
  flake.nixosModules = {
    # shared modules
    common = import ./common.nix;

    # host modules
    #host-arcadia = import ./arcadia;
    #host-hades = import ./hades;
    host-minerva = import ./minerva;
  };

  flake.nixosConfigurations = let
    # make self and inputs available in nixos modules
    specialArgs = {inherit self inputs;};
  in {
    # arcadia = lib.nixosSystem {
    #   inherit specialArgs;
    #   modules = [
    #     inputs.home-manager.nixosModules.home-manager
    #     {
    #       home-manager.useGlobalPkgs = true;
    #       home-manager.useUserPackages = true;
    #       home-manager.extraSpecialArgs = {inherit inputs;};
    #       home-manager.users.brian = {
    #         imports = [(import ./home.nix)];
    #       };
    #     }
    #     self.nixosModules.host-arcadia
    #   ];
    # };
    # hades = lib.nixosSystem {
    #   inherit specialArgs;
    #   modules = [
    #     inputs.home-manager.nixosModules.home-manager
    #     {
    #       home-manager.useGlobalPkgs = true;
    #       home-manager.useUserPackages = true;
    #       home-manager.extraSpecialArgs = {inherit inputs;};
    #       home-manager.users.brian = {
    #         imports = [(import ./home.nix)];
    #       };
    #     }
    #     self.nixosModules.host-hades
    #   ];
    # };
    minerva = lib.nixosSystem {
      inherit specialArgs;
      modules = [self.nixosModules.host-minerva];
    };
  };
}
