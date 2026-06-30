# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = [
    # keep-sorted start
    pkgs.f28335-dump
    pkgs.greatfet
    pkgs.proploader
    pkgs.saleae-logic-2
    pkgs.socat
    pkgs.stm32cubeprogrammer
    pkgs.uniflash
    #pkgs.minicom # TODO needs a fix that is in unstable pipeline
    pkgs.usbutils
    # keep-sorted end
  ];
}
