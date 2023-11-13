# SPDX-License-Identifier: Apache-2.0
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Subsituters
      trusted-public-keys = [
        "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
        "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
      ];
      substituters = [
        "https://cache.vedenemo.dev"
        "https://cache.ssrcdevops.tii.ae"
      ];
      # Avoid copying unecessary stuff over SSH
      builders-use-substitutes = true;

      auto-optimise-store = true; # Optimise syslinks
    };

    # Garbage collection
    gc.automatic = true;
    gc.options = pkgs.lib.mkDefault "--delete-older-than 7d";

    # Keep dependencies that are still in use
    extraOptions = ''
      keep-outputs             = true
      keep-derivations         = true
    '';

    #https://nixos.wiki/wiki/Distributed_build#NixOS
    buildMachines = [
      {
        hostName = "awsarm";
        system = "aarch64-linux";
        maxJobs = 8;
        speedFactor = 1;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        mandatoryFeatures = [];
        #TODO Fix this
        sshUser = "brian";
        sshKey = "/root/.ssh/id_rsa";
      }
    ];

    distributedBuilds = true;
  };

  # Sometimes it fails if a store path is still in use.
  # This should fix intermediate issues.
  systemd.services.nix-gc.serviceConfig = {
    Restart = "on-failure";
  };

  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot/efi";
    binfmt.emulatedSystems = [
      "riscv64-linux"
      "aarch64-linux"
    ];
  };

  # Common network configuration
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.enableIPv6 = false;
  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = false;

  #TODO cleanup
  # security.sudo.enable = true;

  # Contents of the user and group files will be replaced on system activation
  # Ref: https://search.nixos.org/options?channel=unstable&show=users.mutableUsers
  users.mutableUsers = false;

  # Set your time zone (movable so lets set through Gnome)
  #time.timeZone = "dubai/asia";

  # TODO should this be here
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  #TODO Enable and/or move
  #sops.defaultSopsFile = ./secrets/common.yaml;

  # TODO Tidy Shell
  #programs.bash.enableCompletion = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
