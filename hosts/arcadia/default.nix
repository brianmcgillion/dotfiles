# SPDX-License-Identifier: MIT
{
  config,
  lib,
  self,
  ...
}:
{
  #Set the baseline with common.nix
  imports = [ self.nixosModules.common-client ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.wg-privateKeyFile.owner = "root";
    secrets.wg-presharedKeyFile.owner = "root";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

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

  networking = {
    interfaces.enp5s0.useDHCP = true;

    #TODO Replace this with the name of the nixosConfiguration so it can be common
    # Define your hostname
    hostName = lib.mkDefault "arcadia";

    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.7.0.4/24" ];
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

  hardware = {
    cpu.amd.updateMicrocode = true;

    graphics = {
      enable = true;
      #   driSupport32Bit = true;
    };

    nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = false; # was false
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.beta; # was stable
    };
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
