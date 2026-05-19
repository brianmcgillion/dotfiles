# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
_: {
  flake = {
    nixosModules = {
      scripts = import ./scripts;
    };

    overlays.own-pkgs-overlay = final: prev: {
      f28335-dump = final.callPackage ./f28335-dump/default.nix { };
      rebiber = final.callPackage ./rebiber/default.nix { };
      stm32cubeprogrammer = final.callPackage ./stm32cubeprogrammer/default.nix { };
      svd2py = final.callPackage ./svd2py/default.nix { };
      uniflash = final.callPackage ./uniflash/default.nix { };

      # https://github.com/NixOS/nixpkgs/pull/514737
      saleae-logic-2 = prev.saleae-logic-2.overrideAttrs (_old: rec {
        version = "2.4.44";
        src = final.fetchurl {
          url = "https://downloads2.saleae.com/logic2/Logic-${version}-linux-x64.AppImage";
          hash = "sha256-lJp0al4tRqXwb6I8iziCav481XNAuEjASo1ZfUWdYLU=";
        };
      });
    };
  };
}
