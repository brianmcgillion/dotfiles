# SPDX-License-Identifier: Apache-2.0
{
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      treefmt = config.treefmt.build.wrapper;
      packages = [
        pkgs.git
        pkgs.nix
        pkgs.nixos-rebuild
        #TODO Reenable
        #sops-nix
        pkgs.sops
        pkgs.ssh-to-age
        pkgs.deploy-rs
      ];
    };
  };
}
