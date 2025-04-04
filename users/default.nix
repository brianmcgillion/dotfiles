# SPDX-License-Identifier: Apache-2.0
{
  flake.nixosModules = {
    # Individual user modules for direct import if needed
    user-bmg = import ./bmg.nix;
    user-groups = import ./groups.nix;
    user-root = import ./root.nix;
    
    # Combined users module that manages all user modules
    users = import ./users-module.nix;
  };
}
