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
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ./disk-config.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
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
    enable = false;
    isLightHouse = true;
    ca = config.sops.secrets.nebula-ca.path;
    key = config.sops.secrets.nebula-key.path;
    cert = config.sops.secrets.nebula-cert.path;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking = {
    hostName = lib.mkDefault "caelus";
    # Cloud VMs use cloud-init for networking, not NixOS networkd config
    useNetworkd = lib.mkForce false;
  };

  system.stateVersion = "24.05";
}
