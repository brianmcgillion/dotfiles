# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  inputs,
  self,
  lib,
  ...
}:
{
  # Exported as paths (not imported values) so the module system can
  # deduplicate them if a host module is ever imported via two routes.
  flake.nixosModules = {
    # host modules
    host-arcadia = ./arcadia;
    host-argus = ./argus;
    host-minerva = ./minerva;
    host-caelus = ./caelus;
    host-nubes = ./nubes;
  };

  flake.nixosConfigurations =
    let
      # make self and inputs available in nixos modules
      specialArgs = {
        inherit self inputs;
      };

      mkHost = name: {
        inherit specialArgs;
        modules = [
          self.nixosModules."host-${name}"
          # The hostname is the nixosConfigurations attribute name;
          # hosts can still override with a normal assignment.
          { networking.hostName = lib.mkDefault name; }
        ];
      };
    in
    lib.genAttrs [
      "arcadia"
      "argus"
      "caelus"
      "minerva"
      "nubes"
    ] (name: lib.nixosSystem (mkHost name));
}
