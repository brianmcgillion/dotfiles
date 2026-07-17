# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  self,
  lib,
  inputs,
  ...
}:
{
  imports = [
    self.nixosModules.profile-client
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  features = {
    networking = {
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
          address = [ "10.7.0.7/24" ];
        };
      };
    };

    development = {
      # Binary Ninja - only enable on hosts with the zip source available
      binaryninja.enable = true;
      # STM32 development tools with udev rules
      stm32cubeprog.enable = true;
      # TI DSP development tools (UniFlash + XDS200 JTAG)
      uniflash.enable = true;
      # TI C2000 code generation toolchain (cl2000/lnk2000/ar2000) for
      # TMS320F28xxx firmware audit / reverse-engineering work.
      c2000-cgt.enable = true;
    };

    # Per-device keyboard remapping — swap caps/ctrl only on the internal
    # keyboard. The ZSA Voyager is programmable and handles its own layout.
    # Find device IDs with: sudo keyd monitor
    desktop.keyd = {
      enable = true;
      keyboards.internal = {
        ids = [ "0001:0001" ];
        settings.main = {
          capslock = "leftcontrol";
          leftcontrol = "capslock";
        };
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
      luks.devices."luks-beb21201-376c-48a7-bd8f-d1fe91210548".device =
        "/dev/disk/by-uuid/beb21201-376c-48a7-bd8f-d1fe91210548";
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f9a590f0-3553-4e57-a477-91d291999797";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/C0B0-A8A8";
    fsType = "vfat";
    options = [
      "umask=0077"
      "defaults"
    ];
  };

  swapDevices = [ ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "conservative";
  };

  hardware.cpu.intel.updateMicrocode = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
