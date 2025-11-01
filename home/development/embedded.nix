# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    #minicom # TODO needs a fix that is in unstable pipeline
    usbutils
    # keep-sorted end
  ];
}
