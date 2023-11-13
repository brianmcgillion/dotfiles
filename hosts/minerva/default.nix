# SPDX-License-Identifier: MIT
{
  self,
  lib,
  inputs,
  ...
}: {
  # imports = lib.flatten [
  #   [
  #     ./networking.nix
  #     ./hardware-configuration.nix
  #   ]
  # ];
  imports = lib.flatten [
    (with self.nixosModules; [
      audio
      common
      desktop-manager
      emacs
      hardening
      libreoffice
      locale-font
      system-packages
      user-bmg
      user-groups
      xdg
      yubikey
      user-bmg
      user-groups
    ])
    [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.users.brian = {
          imports = [(import ../../home/home.nix)];
        };
      }
    ]
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Origionally in hardware-configuration.nix
  boot = {
    initrd.availableKernelModules = ["xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    # Setup keyfile
    initrd.secrets = {"/crypto_keyfile.bin" = null;};
    initrd.luks.devices."luks-beb21201-376c-48a7-bd8f-d1fe91210548".device = "/dev/disk/by-uuid/beb21201-376c-48a7-bd8f-d1fe91210548";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f9a590f0-3553-4e57-a477-91d291999797";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/C0B0-A8A8";
    fsType = "vfat";
  };

  swapDevices = [];

  #  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "conservative";
  };

  hardware.cpu.intel.updateMicrocode = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.interfaces.wlp0s20f3.useDHCP = true;

  #TODO Replace this with the name of the nixosConfiguration so it can be common
  # Define your hostname
  networking.hostName = "minerva";

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "fi";
}
