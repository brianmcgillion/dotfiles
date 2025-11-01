# SPDX-License-Identifier: MIT
{
  config,
  lib,
  self,
  ...
}:
{
  imports = [
    self.nixosModules.profile-client
    self.nixosModules.hardware-nvidia
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg-privateKeyFile.owner = "root";
    secrets.wg-presharedKeyFile.owner = "root";
    secrets.nebula-ca.owner = config.features.networking.nebula.configOwner;
    secrets.nebula-key.owner = config.features.networking.nebula.configOwner;
    secrets.nebula-cert.owner = config.features.networking.nebula.configOwner;
  };

  # Enable Nebula network
  features.networking.nebula = {
    enable = true;
    isLightHouse = false;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0d91a026-c4f7-4d36-bcec-9a6becdaeb92";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/7BAD-F70E";
    fsType = "vfat";
    options = [
      "umask=0077"
      "defaults"
    ];
  };

  swapDevices = [ ];

  powerManagement = {
    enable = true;
    #let the kernel manage it but here incase
    #cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  networking = {
    interfaces.enp5s0.useDHCP = true;

    #TODO Replace this with the name of the nixosConfiguration so it can be common
    # Define your hostname
    hostName = lib.mkDefault "arcadia";

    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.7.0.4/24" ];
        dns = [ "172.26.0.2" ];
        privateKeyFile = config.sops.secrets.wg-privateKeyFile.path;

        peers = [
          {
            publicKey = "3xZ1Ug4n8XrjZqlrrrveiIPQq3uyMtxuJXII3vCwyww=";
            presharedKeyFile = config.sops.secrets.wg-presharedKeyFile.path;
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "35.178.208.8:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "22.05";
}
