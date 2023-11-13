_: {
  # imports = [
  #     inputs.home-manager.nixosModules.home-manager
  #     {
  #       home-manager.useGlobalPkgs = true;
  #       home-manager.useUserPackages = true;
  #       home-manager.extraSpecialArgs = {inherit inputs;};
  #       home-manager.users.brian = {
  #         imports = [(import ../../home/home.nix)];
  #       };
  #     }
  #   ];
  # inputs = {
  #   home-manager.useGlobalPkgs = true;
  #   home-manager.useUserPackages = true;
  #   home-manager.extraSpecialArgs = {inherit inputs;};
  #   home-manager.users.brian = {
  #     imports = [(import ./home.nix)];
  #   };
  # };
}
