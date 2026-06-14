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

      # bcompare crashes (SIGABRT) when opening any file dialog: the Qt app
      # uses the GTK3 native file chooser, which aborts because its GSettings
      # schema (org.gtk.Settings.FileChooser) is absent from the runtime
      # environment. The upstream package does not wrap it with the GTK
      # schemas. Replicate the essential part of the not-yet-merged
      # https://github.com/NixOS/nixpkgs/pull/517240 by adding wrapGAppsHook3
      # (puts the gtk3 schemas on XDG_DATA_DIRS) and gobject-introspection.
      # Remove this override once that PR lands in our nixpkgs.
      #
      # https://github.com/NixOS/nixpkgs/pull/517240
      bcompare = prev.bcompare.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          final.wrapGAppsHook3
          final.gobject-introspection
        ];
      });

      # Convenience top-level alias so greatfet (which nixpkgs only exposes under
      # python3Packages) is referenced as `pkgs.greatfet` like our other tools.
      greatfet = final.python3Packages.greatfet;
    };
  };
}
