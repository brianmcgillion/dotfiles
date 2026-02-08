# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = [
    # keep-sorted start
    pkgs.socat
    #pkgs.minicom # TODO needs a fix that is in unstable pipeline
    pkgs.usbutils
    # keep-sorted end
  ];
}
