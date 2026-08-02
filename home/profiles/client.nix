# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Home-manager client profile
{ ... }:
{
  imports = [
    ../home.nix
    ../apps
    ../browsers
    ../desktop
    ../development
    ../security
    ../shell
  ];
}
