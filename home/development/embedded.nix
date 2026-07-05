# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  home.packages =
    [
      # keep-sorted start
      pkgs.proploader
      pkgs.socat
      #pkgs.minicom # TODO needs a fix that is in unstable pipeline
      pkgs.usbutils
      # keep-sorted end
    ]
    ++ lib.optionals osConfig.features.development.greatfet.enable [ pkgs.greatfet ]
    ++ lib.optionals osConfig.features.development.saleae-logic.enable [ pkgs.saleae-logic-2 ]
    ++ lib.optionals osConfig.features.development.stm32cubeprog.enable [ pkgs.stm32cubeprogrammer ]
    ++ lib.optionals osConfig.features.development.uniflash.enable [
      pkgs.f28335-dump
      pkgs.uniflash
    ];
}
