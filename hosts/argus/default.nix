# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  pkgs,
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

  time.timeZone = "Asia/Dubai";

  # ollama-cuda is not on cache.nixos.org (unfree CUDA); without this cache
  # every nixpkgs bump triggers a long local CUDA rebuild.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  sops.defaultSopsFile = ./secrets.yaml;

  features = {
    ai.ollama.enable = true;

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
          address = [ "10.7.0.11/24" ];
          # TODO: intentional? The other clients use the VPN-internal resolver
          # (172.26.0.2, from the bmg-vps network); with 8.8.8.8 internal names
          # will not resolve while the tunnel is up.
          dns = [ "8.8.8.8" ];
        };
      };
    };

    system = {
      # This box out-builds the shared x86 builder, and offloading costs a
      # round trip of the closure over ssh. aarch64 stays remote — building
      # it here would mean qemu emulation.
      remote-builders.offloadSystems = [ "aarch64-linux" ];
    };

    # logind's idle timer only tracks input activity, not load, so long
    # unattended builds and ollama runs were being suspended out from under
    # themselves after ~35 min (GNOME's 5 min idle-delay + logind's 30 min
    # IdleActionSec). This is a mains-powered workstation — never auto-suspend.
    desktop.power-management.idleAction = "ignore";
  };

  boot = {
    swraid.enable = true;
    swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
    loader.efi.efiSysMountPoint = "/boot";
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "uas"
        "sd_mod"
      ];
      kernelModules = [
        "raid0"
        "dm-mod"
      ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  powerManagement = {
    enable = true;
    #let the kernel manage it but here incase
    #cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  networking.interfaces.enp173s0.useDHCP = true;

  # RTX 5090 (Blackwell/GB202) requires open kernel modules
  hardware.nvidia.open = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "25.11";
}
