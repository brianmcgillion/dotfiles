# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = [
    # keep-sorted start
    pkgs.element-desktop
    pkgs.slack
    #pkgs.zoom-us
    # keep-sorted end
  ];
}
