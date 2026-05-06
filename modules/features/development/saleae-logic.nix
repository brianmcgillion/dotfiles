# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# Saleae Logic 2 - logic analyzer software
#
# Provides udev rules for Saleae Logic USB devices so they can be
# accessed without root privileges.
#
# Usage:
#   features.development.saleae-logic.enable = true;
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.development.saleae-logic;
in
{
  options.features.development.saleae-logic = {
    enable = lib.mkEnableOption "Saleae Logic analyzer udev rules";
  };

  config = lib.mkIf cfg.enable {
    hardware.saleae-logic.enable = true;
  };
}
