# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# YubiKey hardware authentication support
#
# Configures system support for YubiKey hardware security keys.
# Enables smartcard services and installs management tools.
#
# Features:
# - YubiKey Manager CLI and GUI tools
# - age-plugin-yubikey for age encryption
# - Touch detector for notification when YubiKey interaction is needed
# - PCSCD smartcard daemon
# - Udev rules for YubiKey device access
#
# Usage:
#   features.desktop.yubikey.enable = true;
#
# Enabled by default in: profile-client
#
# Common use cases:
# - SSH authentication with hardware keys
# - GPG signing with YubiKey
# - Age encryption with YubiKey
# - 2FA/U2F authentication
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.yubikey;
in
{
  options.features.desktop.yubikey = {
    enable = lib.mkEnableOption "YubiKey support";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      # keep-sorted start
      pkgs.age
      pkgs.age-plugin-yubikey
      pkgs.yubikey-manager
      pkgs.yubikey-touch-detector
      # keep-sorted end
    ];

    services.pcscd.enable = true;
    services.udev.packages = [ pkgs.yubikey-manager ];
  };
}
