# SPDX-License-Identifier: Apache-2.0
{
  lib,
  self,
  inputs,
  config,
  ...
}:
{
  imports = [
    self.nixosModules.common-server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ./disk-config.nix
  ];

  # Nebula config is already enabled in my-nebula-network
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.nebula-ca.owner = config.my-nebula-network.configOwner;
    secrets.nebula-key.owner = config.my-nebula-network.configOwner;
    secrets.nebula-cert.owner = config.my-nebula-network.configOwner;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    loader.grub = {
      enable = true;
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  #
  # Disko will define all the file systems for us
  # So no need to call each out here
  #
  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostName = lib.mkDefault "nephele";
  };

  my-nebula-network = {
    enable = true;
    isLightHouse = false;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
  };

  systemd.network.networks."10-uplink".networkConfig.Address = "65.109.25.143";
  system.stateVersion = "24.05"; # Did you read the comment?
}
