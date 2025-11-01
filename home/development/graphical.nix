# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  # graphical tools used for development
  home.packages = with pkgs; [
    bcompare
    mendeley
  ];
  #services.flameshot.enable = true;
}
