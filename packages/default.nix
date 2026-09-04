# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, ... }:
{
  # Expose the overlay's CI-buildable packages as flake outputs so the
  # package-<name> checks in nix/checks.nix actually build them.
  #
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs)
          rebiber
          remarkable-sync
          ;
      };
    };

  flake = {
    nixosModules = {
      scripts = ./scripts;
    };

    overlays.own-pkgs-overlay =
      final: prev:
      let
        # AI coding agents sourced from numtide/llm-agents.nix (see flake.nix).
        # Aliasing claude-code / claude-agent-acp here routes every existing
        # `pkgs.claude-code` reference (system packages, the home-manager plugin
        # sync `runtimeInputs`, etc.) to the faster-moving llm-agents build.
        llm = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
      in
      {
        inherit (llm) claude-code;
        inherit (llm) claude-agent-acp;
        inherit (llm) ccusage;
        inherit (llm) ccstatusline;
        inherit (llm) coderabbit-cli;
        inherit (llm) opencode;
        inherit (llm) oh-my-opencode;

        rebiber = final.callPackage ./rebiber/default.nix { };
        remarkable-sync = final.callPackage ./remarkable-sync/default.nix { };

        # Convenience top-level alias so greatfet (which nixpkgs only exposes under
        # python3Packages) is referenced as `pkgs.greatfet` like our other tools.
        greatfet = final.python3Packages.greatfet;

        # Work around python3Packages.pyqt5 failing to build against the pinned
        # nixpkgs: sip 6.15.1 -> 6.16.1 made the generated bindings target an
        # ABI that PyQt5 5.15.10's QtCore does not support, so the build dies
        # with "ABI v12 is being targeted but the PyQt5.QtCore module doesn't
        # support it". Nothing else moved -- python (3.14.7), pyqt5 (5.15.10),
        # pyqt5-sip (12.17.0) and pyqt-builder (1.19.1) are identical either
        # side of the bump. This blocks every rebuild rather than just PyQt5
        # users: texliveMedium -> asymptote -> a python env containing pyqt5,
        # and texlive is in system-path via features.development.emacs-ui.
        # Scoped to pyqt5's own sip rather than pinning the package set, so
        # anything else wanting 6.16.1 still gets it. Fixed upstream in
        # NixOS/nixpkgs#559495, which patches sip 6.16.1 rather than pinning it
        # back; merged to master 2026-09-03 but not yet in nixos-unstable. Drop
        # once the channel carries it.
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyFinal: pyPrev: {
            pyqt5 = pyPrev.pyqt5.override {
              sip = pyPrev.sip.overridePythonAttrs (_old: {
                version = "6.15.1";
                src = pyPrev.fetchPypi {
                  pname = "sip";
                  version = "6.15.1";
                  hash = "sha256-3C5YwXmKdOGzHCjoNzOYIv6PpVKIrjDomG6ygQDrylo=";
                };
              });
            };
          })
        ];
      };
  };
}
