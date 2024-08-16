# SPDX-License-Identifier: Apache-2.0
{
  lib,
  self,
  modulesPath,
  ...
}:
{
  imports = [
    #A cloud based Hetzner instance so running as a VM on shared host
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.common-server
    ./disk-config.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
      "sd_mod"
      "sr_mod"
    ];
    initrd.kernelModules = [ ];
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
    interfaces.ens3.useDHCP = lib.mkDefault true;
    hostName = "caelus";
  };

  # It is not moving so lock it down
  time.timeZone = "Europe/Helsinki";

  system.stateVersion = "24.05"; # Did you read the comment?
}
