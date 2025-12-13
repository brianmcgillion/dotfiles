# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Home-manager module exports
_: {
  flake.homeModules = {
    # Home-manager profiles
    home-profile-client = import ./profiles/client.nix;
    home-profile-server = import ./profiles/server.nix;
  };
}
