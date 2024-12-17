# SPDX-License-Identifier: Apache-2.0
{
  lib,
  self,
  inputs,
  ...
}:
{
  imports = [
    self.nixosModules.common-server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ./disk-config.nix
  ];

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

  systemd.network.networks."10-uplink".networkConfig.Address = "65.109.25.143";
  system.stateVersion = "24.05"; # Did you read the comment?
}
