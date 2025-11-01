# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #TODO needs a fix that is in unstable pipeline
    #minicom
    usbutils
  ];
}
