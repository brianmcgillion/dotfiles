# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
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
    ./disk-config.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      wg-privateKeyFile.owner = "root";
      wg-presharedKeyFile.owner = "root";
      nebula-ca.owner = config.features.networking.nebula.configOwner;
      nebula-key.owner = config.features.networking.nebula.configOwner;
      nebula-cert.owner = config.features.networking.nebula.configOwner;
    };
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
    loader.efi.efiSysMountPoint = "/boot";
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
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  powerManagement = {
    enable = true;
    #let the kernel manage it but here incase
    #cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  networking = {
    interfaces.enp4s0.useDHCP = true;

    #TODO Replace this with the name of the nixosConfiguration so it can be common
    # Define your hostname
    hostName = lib.mkDefault "argus";

    wg-quick.interfaces = {
      wg0 = {
        autostart = false;
        address = [ "10.7.0.11/24" ];
        dns = [ "8.8.8.8" ];
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

  hardware.cpu.intel.updateMicrocode = true;

  system.stateVersion = "25.11";
}
