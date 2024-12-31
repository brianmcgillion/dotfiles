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
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ./disk-config.nix
  ];

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
        "ata_piix"
        "virtio_pci"
        "virtio_scsi"
        "xhci_pci"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
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

  hardware.cpu.intel.updateMicrocode = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking = {
    hostName = lib.mkDefault "caelus";
  };

  my-nebula-network = {
        enable = true;
        isLightHouse = true;
        ca = config.sops.secrets.nebula-ca.path;
        key = config.sops.secrets.nebula-key.path;
        cert = config.sops.secrets.nebula-cert.path;
      };

  system.stateVersion = "24.05"; # Did you read the comment?
}
