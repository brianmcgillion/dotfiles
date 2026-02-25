# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  config,
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

  # Enable Nebula network
  features.networking.nebula = {
    enable = true;
    isLightHouse = false;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
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

  networking = {
    interfaces.enp173s0.useDHCP = true;

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

  # RTX 5080 (Blackwell/GB203) requires open kernel modules
  hardware.nvidia.open = true;
  # Pin to 6.12 LTS: nvidia-open doesn't compile against 6.19 yet
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "25.11";
}
