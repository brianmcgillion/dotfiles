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
        inherit (llm) opencode;
        inherit (llm) oh-my-opencode;

        rebiber = final.callPackage ./rebiber/default.nix { };
        remarkable-sync = final.callPackage ./remarkable-sync/default.nix { };

        # Convenience top-level alias so greatfet (which nixpkgs only exposes under
        # python3Packages) is referenced as `pkgs.greatfet` like our other tools.
        greatfet = final.python3Packages.greatfet;
      };
  };
}
