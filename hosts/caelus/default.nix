# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  self,
  inputs,
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

  sops.defaultSopsFile = ./secrets.yaml;

  # Nebula lighthouse for the pantheon overlay (secrets wired from
  # ./secrets.yaml)
  features.networking.nebula = {
    enable = true;
    isLighthouse = true;
    useSopsSecrets = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Hetzner cloud provides native IPv6; keep it enabled on servers.
  networking.enableIPv6 = true;

  system.stateVersion = "24.05";
}
