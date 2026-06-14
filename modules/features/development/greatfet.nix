# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# GreatFET One - hardware-hacking multitool
#
# Provides udev rules so the GreatFET (and its NXP DFU bootloader) can be
# accessed without root privileges.
#
# Usage:
#   features.development.greatfet.enable = true;
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.development.greatfet;
in
{
  options.features.development.greatfet = {
    enable = lib.mkEnableOption "GreatFET One udev rules";
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # GreatFET One (normal operation)
      SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="60e6", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="greatfet-one%k"
      # NXP LPC DFU bootloader (firmware flash / recovery)
      SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="000c", MODE="0660", GROUP="plugdev", TAG+="uaccess", SYMLINK+="nxp-dfu-%k"
    '';
  };
}
