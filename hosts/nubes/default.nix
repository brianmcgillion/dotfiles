# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  self,
  inputs,
  config,
  ...
}:
{
  imports = [
    self.nixosModules.profile-server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ./disk-config.nix
  ];

  # Use GRUB instead of systemd-boot (more reliable for Hetzner)
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      nebula-ca.owner = config.features.networking.nebula.configOwner;
      nebula-key.owner = config.features.networking.nebula.configOwner;
      nebula-cert.owner = config.features.networking.nebula.configOwner;
    };
  };

  features.networking.nebula = {
    enable = true;
    isLightHouse = false;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Ghaf project binary cache (used with nix-fast-build)
  # Priority 50 ensures cache.nixos.org (default priority 40) is checked first
  nix.settings = {
    extra-substituters = [ "https://ghaf-dev.cachix.org?priority=50" ];
    extra-trusted-public-keys = [
      "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
    ];
  };

  networking = {
    hostName = lib.mkDefault "nubes";
  };

  systemd.network = {
    enable = true;
    networks."10-uplink".networkConfig.Address = [
      "2a01:4f9:6b:2345::1/64" # IPv6
      "65.108.111.248/32" # IPv4
    ];
  };

  system.stateVersion = "25.11";
}
