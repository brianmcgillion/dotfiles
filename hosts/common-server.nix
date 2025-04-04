# SPDX-License-Identifier: Apache-2.0
{
  self,
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    # Import the single top-level module
    self.nixosModules.system-config
    
    # Keep any external imports
    ./common.nix
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
    
    # Enable server-specific modules through the setup interface
    setup.modules = {
      server = true;
      fail2ban = true;
      sshd = true;
    };
    
    # The users setup is already handled in common.nix
    # and will automatically set enableRoot to true for servers
    
    environment.systemPackages = [ pkgs.kitty.terminfo ];
    services.avahi.enable = false;
  };
}
