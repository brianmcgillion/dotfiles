# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
_: {
  flake = {
    nixosModules = {
      scripts = import ./scripts;
    };

    overlays.own-pkgs-overlay = final: _prev: {
      rebiber = final.callPackage ./rebiber/default.nix { };
    };
  };
}
