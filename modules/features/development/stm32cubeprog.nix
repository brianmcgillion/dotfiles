# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# STM32CubeProgrammer - programming tool for STM32 microcontrollers
#
# Provides CLI and GUI tools for programming STM32 devices via
# JTAG, SWD, USB DFU, UART, SPI, CAN, and I2C interfaces.
#
# Usage:
#   features.development.stm32cubeprog.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.stm32cubeprog;
in
{
  options.features.development.stm32cubeprog = {
    enable = lib.mkEnableOption "STM32CubeProgrammer with udev rules";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.stm32cubeprogrammer
    ];

    # Install udev rules for ST-Link and DFU devices
    services.udev.packages = [ pkgs.stm32cubeprogrammer ];
  };
}
