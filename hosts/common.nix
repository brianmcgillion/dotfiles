# SPDX-License-Identifier: Apache-2.0
{
  self,
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    (with self.nixosModules; [
      audio
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
    ])
    [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.users.brian = {
          imports = [(import ../home/home.nix)];
        };
      }
    ]
  ];

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
      # trusted-public-keys = [
      #   "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      #   "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
      # ];
      # substituters = [
      #   "https://cache.vedenemo.dev"
      #   "https://cache.ssrcdevops.tii.ae"
      # ];
      # Avoid copying unecessary stuff over SSH
      builders-use-substitutes = true;
      trusted-users = ["root" "brian"];
      auto-optimise-store = true; # Optimise syslinks
    };

    # Garbage collection
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = pkgs.lib.mkDefault "--delete-older-than 7d";
    };

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
        sshKey = "/home/brian/.ssh/id_rsa";
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
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host awsarm
        HostName awsarm.vedenemo.dev
        Port 20220
    '';
    knownHosts = {
      awsarm-ed25519 = {
        hostNames = ["awsarm.vedenemo.dev"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3f7tAAO3Fc+8BqemsBQc/Yl/NmRfyhzr5SFOSKqrv0";
      };
      awsarm-rsa = {
        hostNames = ["awsarm.vedenemo.dev"];
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtP5yuGAaMGK4GPsViPCIZvaPXN2tPoZH59i6CtPA1Vg8JzRX9g2PgFmUbNtQ9nxQhtUlVbNddCxoEKPJt+VgL/23o1DXM+EauuGOp9PijfcNqDq2jvwW1yoCnxMyA53vC7gR6CYGdu9BhQJYK9S4SaHtf4RcfUa39uWPfUCIKUyG9vB+T9p7E86O+pLBMRpAvppitFLdkxgAYZeedFUvhIQQZlTTJ7ELT3bJry5S+aBck83uZuU1guklyvCR9cZLMiAG2N4Goo/mH11kS4ytMV0AvpY2x4qY40wQvb3gGDYj53WArTkTf52yHELDbtCnjlwFW+5hJBog6CQaxy0S8eSN4MBbM2czmXh3sofwW7iB3iXr6q7IpTzcpeaiawau/OucTBnjVF+wm8C8MV3ekmEyTD+xEGQxESgJgqTLnHD3EKWm4qCTZBhq+XuazVP60eKvK5OVcIxsKHP4WO0YvP8oyjT62ur60wVKtJ2FJ3f0SAtSM2igV2KuDgdi3lek=";
      };
      awsarm-eddsa = {
        hostNames = ["awsarm.vedenemo.dev"];
        publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNH+bPKgI9X7G1/MYq8fUSIkOyL2TmhH0quYlbX8fb9Z0AG6qRcNHaoFFIJaKxWEcAafo+hZNI1A9LKsY9MYXtE=";
      };
    };
  };
  services.openssh.startWhenNeeded = false;

  # Contents of the user and group files will be replaced on system activation
  # Ref: https://search.nixos.org/options?channel=unstable&show=users.mutableUsers
  users.mutableUsers = false;

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  #TODO Enable and/or move
  #sops.defaultSopsFile = ./secrets/common.yaml;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
