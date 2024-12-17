# SPDX-License-Identifier: Apache-2.0
{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    self.nixosModules.user-root
    self.nixosModules.sshd
    inputs.disko.nixosModules.disko
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-terminfo
  ];

  config = {
    setup.device.isServer = true;

    environment.systemPackages = [ pkgs.kitty.terminfo ];
  };
}
