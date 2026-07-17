# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, ... }:
{
  # Expose the overlay's CI-buildable packages as flake outputs so the
  # package-<name> checks in nix/checks.nix actually build them.
  # Excluded on purpose: stm32cubeprogrammer (requireFile vendor blob that
  # must be staged manually) and uniflash (multi-hundred-MB unfree vendor
  # installer not worth building in every flake check).
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs)
          f28335-dump
          proploader
          rebiber
          remarkable-sync
          svd2py
          ;
      };
    };

  flake = {
    nixosModules = {
      scripts = ./scripts;
    };

    overlays.own-pkgs-overlay =
      final: _prev:
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

        f28335-dump = final.callPackage ./f28335-dump/default.nix { };
        proploader = final.callPackage ./proploader/default.nix { };
        rebiber = final.callPackage ./rebiber/default.nix { };
        remarkable-sync = final.callPackage ./remarkable-sync/default.nix { };
        stm32cubeprogrammer = final.callPackage ./stm32cubeprogrammer/default.nix { };
        svd2py = final.callPackage ./svd2py/default.nix { };
        uniflash = final.callPackage ./uniflash/default.nix { };

        # Convenience top-level alias so greatfet (which nixpkgs only exposes under
        # python3Packages) is referenced as `pkgs.greatfet` like our other tools.
        greatfet = final.python3Packages.greatfet;
      };
  };
}
