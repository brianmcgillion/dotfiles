# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  binaryninja-src = pkgs.runCommand "binaryninja_linux_dev_ultimate.zip" { } ''
    cp ${inputs.binary-ninja-source} $out
  '';
in
{
  # Not using inputs.nix-binary-ninja.hmModules.binaryninja because it sets
  # nixpkgs.overlays in the home-manager scope, which is incompatible with
  # home-manager.useGlobalPkgs. Instead, add the package directly.
  home.packages = lib.optionals osConfig.features.development.binaryninja.enable [
    (
      (inputs.nix-binary-ninja.packages.x86_64-linux.binary-ninja-ultimate.override {
        overrideSource = binaryninja-src;
      }).overrideAttrs
      (_old: {
        # Binary Ninja bundles Qt 6.10.1, which is incompatible with the
        # nixpkgs Qt 6.10.2 platform plugins injected by wrapQtAppsHook.
        # Replace the installPhase to:
        # 1. Keep the bundled Qt .so files (skip the find -delete)
        # 2. Not pass qtWrapperArgs to makeWrapper (avoids mismatched QT_PLUGIN_PATH)
        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          mkdir -p $out/opt/binaryninja
          mkdir -p $out/share/pixmaps
          cp -r * $out/opt/binaryninja
          cp ${
            pkgs.fetchurl {
              url = "https://docs.binary.ninja/img/logo.png";
              hash = "sha256-TzGAAefTknnOBj70IHe64D6VwRKqIDpL4+o9kTw0Mn4=";
            }
          } $out/share/pixmaps/binaryninja.png
          chmod +x $out/opt/binaryninja/binaryninja
          buildPythonPath "$pythonDeps"
          makeWrapper $out/opt/binaryninja/binaryninja $out/bin/binaryninja \
            --prefix PYTHONPATH : "$program_PYTHONPATH"

          runHook postInstall
        '';
      })
    )
  ];
}
