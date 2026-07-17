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
    inputs.srvos.nixosModules.hardware-hetzner-online-amd
    ./disk-config.nix
  ];

  # GRUB instead of systemd-boot: installs as removable EFI media, which
  # survives Hetzner's rescue system and NVRAM resets.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  sops.defaultSopsFile = ./secrets.yaml;

  # Enable Nebula network (secrets wired from ./secrets.yaml)
  features.networking.nebula = {
    enable = true;
    useSopsSecrets = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Hetzner assigns a static IPv6 block; without this the 2a01:... address
  # below is dead config (the fleet default disables IPv6).
  networking.enableIPv6 = true;

  # networkd itself is enabled by the srvos hetzner-online module.
  systemd.network.networks."10-uplink".networkConfig.Address = [
    "2a01:4f9:6b:2345::1/64" # IPv6
    "65.108.111.248/32" # IPv4
  ];

  system.stateVersion = "25.11";
}
