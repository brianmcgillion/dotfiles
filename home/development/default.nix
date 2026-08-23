# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, ... }:
{
  imports = [
    ./base-system.nix
    ./claude
    ./copilot.nix
    ./graphical.nix
    ./embedded.nix
    inputs.seclab-pkgs.homeModules.binaryninja
  ];
}
