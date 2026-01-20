# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Home-manager module exports
{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeModules = {
    home-profile-client = import ./profiles/client.nix;
    home-profile-server = import ./profiles/server.nix;
  };
}
