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
  # Binary Ninja ships as an out-of-tree zip that cannot be a flake input: a
  # missing/absent file would break `nix flake update` on every host, including
  # those that never install Binary Ninja. requireFile keeps it out of flake
  # evaluation entirely - it is only forced when the binaryninja feature is
  # enabled and something builds it. Provision the zip once on hosts that need
  # it with:
  #   nix-store --add-fixed sha256 <path>/binaryninja_linux_dev_ultimate.zip
  binaryninja-src = pkgs.requireFile {
    name = "binaryninja_linux_dev_ultimate.zip";
    sha256 = "1bbg49n6976z44qrdkw3j5yv73vvfa9yc3djbw82pd8ng8vdf9bs";
    message = ''
      Binary Ninja source zip is not in the Nix store. Add it with:
        nix-store --add-fixed sha256 <path>/binaryninja_linux_dev_ultimate.zip
    '';
  };

  # Python packages required by Binary Ninja plugins
  pluginPythonDeps = with pkgs.python3Packages; [
    click
    pyyaml
    pkgs.svd2py
  ];
in
{
  # Not using inputs.nix-binary-ninja.hmModules.binaryninja because it sets
  # nixpkgs.overlays in the home-manager scope, which is incompatible with
  # home-manager.useGlobalPkgs. Instead, add the package directly.
  # TMS320C28x plugin is now a Rust native .so deployed manually from
  # tms320c28x-re/rust/target/release/libtms320c28x_binja.so
  # into ~/.binaryninja/plugins/

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
          pluginPythonPath="${pkgs.python3.pkgs.makePythonPath pluginPythonDeps}"
          makeWrapper $out/opt/binaryninja/binaryninja $out/bin/binaryninja \
            --prefix PYTHONPATH : "$program_PYTHONPATH:$pluginPythonPath"

          runHook postInstall
        '';
      })
    )
  ];
}
