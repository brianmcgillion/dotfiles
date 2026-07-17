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

  # Enable AI features (CUDA auto-detected from hardware-nvidia)
  # Note: Qwen3-Coder-480B-A35B is the best Qwen coding model but requires a cluster of GPUs
  features.ai = {
    enable = true;
    ollama.models = [
      "llama3.2:3b"
      "qwen3-coder-next" # 80B MoE, 3B active — best local coding model (needs ~52GB RAM+VRAM)
      "qwen3:30b-a3b" # 30B MoE, 3.3B active — fits fully in GPU VRAM
    ];
  };

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
        address = [ "10.7.0.11/24" ];
        # TODO: intentional? The other clients use the VPN-internal resolver
        # (172.26.0.2, from the bmg-vps network); with 8.8.8.8 internal names
        # will not resolve while the tunnel is up.
        dns = [ "8.8.8.8" ];
      };
    };
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

  # RTX 5080 (Blackwell/GB203) requires open kernel modules
  hardware.nvidia.open = true;
  # Track the latest kernel: nvidia-open (595.84) builds against 7.x again, so
  # the old 6.12 pin is no longer needed. linuxPackages_latest is a moving
  # target - if a future nixpkgs bump outruns nvidia-open, pin a series instead
  # (e.g. linuxPackages_7_1).
  # Plain assignment (no mkForce) so a future module pinning a kernel for a
  # hardware reason surfaces as a conflict instead of being silently overridden.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "25.11";
}
