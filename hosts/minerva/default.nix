# SPDX-License-Identifier: MIT
{
  self,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    self.nixosModules.profile-client
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg-privateKeyFile.owner = "root";
    secrets.wg-presharedKeyFile.owner = "root";
    secrets.nebula-ca.owner = config.features.networking.nebula.configOwner;
    secrets.nebula-key.owner = config.features.networking.nebula.configOwner;
    secrets.nebula-cert.owner = config.features.networking.nebula.configOwner;
  };

  # Enable Nebula network
  features.networking.nebula = {
    enable = true;
    isLightHouse = false;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
  };

  # Enable SSH server for this laptop
  features.security.sshd.enable = true;

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
      # Setup keyfile
      secrets = {
        "/crypto_keyfile.bin" = null;
      };
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
  networking = {
    interfaces.wlp0s20f3.useDHCP = true;

    #TODO Replace this with the name of the nixosConfiguration so it can be common
    # Define your hostname
    hostName = lib.mkDefault "minerva";

    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.7.0.7/24" ];
        dns = [ "172.26.0.2" ];
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

  # Configure keymap in X11
  services.xserver.xkb = {
    options = "ctrl:swapcaps";
  };

  console.useXkbConfig = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
