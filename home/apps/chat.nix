# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    element-desktop
    slack
    #zoom-us
    # keep-sorted end
  ];
}
