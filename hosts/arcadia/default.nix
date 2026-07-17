# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
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

  sops.defaultSopsFile = ./secrets.yaml;

  features.networking = {
    # Enable Nebula network (secrets wired from ./secrets.yaml)
    nebula = {
      enable = true;
      useSopsSecrets = true;
    };

    # Personal WireGuard VPN (wg-quick up wg0)
    wireguard = {
      enable = true;
      tunnels.wg0 = {
        network = "bmg-vps";
        address = [ "10.7.0.4/24" ];
      };
    };
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

  networking.interfaces.enp5s0.useDHCP = true;

  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "22.05";
}
