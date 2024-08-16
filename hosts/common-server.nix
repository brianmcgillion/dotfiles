# SPDX-License-Identifier: Apache-2.0
{
  self,
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    self.nixosModules.user-root
    self.nixosModules.sshd
    inputs.disko.nixosModules.disko
  ];

  config = {
    setup.device.isServer = true;

    environment.systemPackages = [ pkgs.kitty.terminfo ];
  };
}
