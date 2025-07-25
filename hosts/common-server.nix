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
    inputs.srvos.nixosModules.mixins-mdns
    inputs.srvos.nixosModules.roles-nix-remote-builder
    {
      #TODO: set the key programmatically
      roles.nix-remote-builder.schedulerPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu6O3swRVWAjP7J8iYGT6st7NAa+o/XaemokmtKdpGa builder key"
      ];
    }
  ];

  config = {
    setup.device.isServer = true;
    environment.systemPackages = [
      pkgs.kitty.terminfo
      pkgs.ghostty.terminfo
    ];
    services.avahi.enable = false;

    networking = {
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
  };
}
