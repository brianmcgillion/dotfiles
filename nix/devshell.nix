# SPDX-License-Identifier: Apache-2.0
{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        git
        nix
        nixos-rebuild
        #TODO Reenable
        #        sops-nix
        ssh-to-age
      ];
    };
  };
}
