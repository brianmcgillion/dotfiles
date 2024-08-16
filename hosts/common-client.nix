# SPDX-License-Identifier: MIT
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (with self.nixosModules; [
      audio
      desktop-manager
      emacs-ui
      emacs
      libreoffice
      locale-font
      yubikey
    ])
    [ ./common.nix ]
  ];

  config = {
    setup.device.isClient = true;

    # Bootloader, seems server is MBR in most cases.
    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.efi.canTouchEfiVariables = true;
      loader.efi.efiSysMountPoint = "/boot/efi";
    };

    # Common network configuration
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    networking = {
      networkmanager.enable = true;
      #Open ports in the firewall?
      firewall = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
    };

    #By default the client devices to not provide inbound ssh
    services.openssh.startWhenNeeded = false;
    # enable the fwupdate daemon to install fw changes
    services.fwupd.enable = true;

    #
    # Setup the zsa keyboards
    #
    environment.systemPackages = with pkgs; [
      wally-cli # ergodox configuration tool
      keymapp
    ];

    hardware.keyboard.zsa.enable = true;

    # nix.buildMachines = [
    #   {
    #     # include nephele here to avoid recursion
    #     hostName = "nephele";
    #     system = "x86_64-linux";
    #     maxJobs = 8;
    #     speedFactor = 1;
    #     supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
    #     mandatoryFeatures = [];
    #     #TODO Fix this
    #     sshUser = "brian";
    #     sshKey = "/home/brian/.ssh/builder-key";
    #   }
    # ];
  };
}
