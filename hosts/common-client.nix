# SPDX-License-Identifier: MIT
{
  self,
  lib,
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = lib.flatten [
    [
      # Import the single top-level module
      self.nixosModules.system-config
      
      # Keep any external imports
      ./common.nix
      inputs.srvos.nixosModules.desktop
    ]
  ];

  config = {
    setup.device.isClient = true;
    
    # Enable modules through the setup interface
    setup.modules = {
      audio = true;
      client = true;
      emacs = true;
      emacs-ui = true;
      desktop = true;
      yubikey = true;
    };

    # define the secrets stored in sops and the relative owners for them.
    sops = {
      #defaultSopsFile is specific to a client so in their config module
      secrets.wg-privateKeyFile.owner = "root";
      secrets.wg-presharedKeyFile.owner = "root";
      secrets.nebula-ca.owner = config.my-nebula-network.configOwner;
      secrets.nebula-key.owner = config.my-nebula-network.configOwner;
      secrets.nebula-cert.owner = config.my-nebula-network.configOwner;
    };

    # Bootloader, seems server is MBR in most cases.
    boot = {
      #boot.initrd.systemd.enable is true from srvos
      loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 5;
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = "/boot/efi";
      };
    };

    # Common network configuration
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    networking = {
      networkmanager.enable = true;
      #Open ports in the firewall?
      firewall = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
    };

    my-nebula-network = {
      enable = true;
      isLightHouse = false;
      ca = config.sops.secrets.nebula-ca.path;
      key = config.sops.secrets.nebula-key.path;
      cert = config.sops.secrets.nebula-cert.path;
    };

    #By default the client devices to not provide inbound ssh
    services = {
      openssh.startWhenNeeded = false;
      # enable the fwupdate daemon to install fw changes
      fwupd.enable = true;
    };

    #
    # Setup the zsa keyboards
    #
    environment.systemPackages = with pkgs; [
      wally-cli # ergodox configuration tool
      keymapp
    ];

    hardware.keyboard.zsa.enable = true;

    # Enable developer documentation (man 3) pages
    documentation = {
      dev.enable = true;
      # This is slow for the first build
      # man.generateCaches = true;
    };
  };
}
