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
    inputs.srvos.nixosModules.roles-nix-remote-builder
    {
      #TODO: set the key programatically
      roles.nix-remote-builder.schedulerPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu6O3swRVWAjP7J8iYGT6st7NAa+o/XaemokmtKdpGa builder key"
      ];
    }
  ];

  config = {
    setup.device.isServer = true;

    environment.systemPackages = [ pkgs.kitty.terminfo ];
  };
}
