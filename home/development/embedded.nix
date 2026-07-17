# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  # usbutils comes from the client profile; stm32cubeprogrammer and uniflash
  # are installed system-wide by their feature modules (alongside their udev
  # rules) — do not duplicate them here.
  home.packages = [
    # keep-sorted start
    pkgs.proploader
    pkgs.socat
    #pkgs.minicom # TODO needs a fix that is in unstable pipeline
    # keep-sorted end
  ]
  ++ lib.optionals osConfig.features.development.greatfet.enable [ pkgs.greatfet ]
  ++ lib.optionals osConfig.features.development.saleae-logic.enable [ pkgs.saleae-logic-2 ]
  ++ lib.optionals osConfig.features.development.uniflash.enable [ pkgs.f28335-dump ];
}
