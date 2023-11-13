# SPDX-License-Identifier: Apache-2.0
{
  flake.nixosModules = {
    user-bmg = import ./bmg.nix;
    user-groups = import ./groups.nix;
  };
}
