# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# TI UniFlash - programming tool for TI microcontrollers and DSPs
#
# Provides CLI (dslite) and GUI tools for programming TI devices via
# JTAG (XDS200, XDS110), SWD, and serial interfaces.
#
# Usage:
#   features.development.uniflash.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.uniflash;
in
{
  options.features.development.uniflash = {
    enable = lib.mkEnableOption "TI UniFlash with udev rules for XDS debug probes";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.uniflash
    ];

    # Install udev rules for XDS200/XDS110 and other TI debug probes
    services.udev.packages = [ pkgs.uniflash ];
  };
}
