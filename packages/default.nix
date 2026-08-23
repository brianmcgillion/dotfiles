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

        # Work around ollama-cuda failing to build against the pinned nixpkgs:
        # cmake 4.3.4 (nixpkgs #529977) made find_package(CUDAToolkit) hard-fail
        # when CUDAToolkit_ROOT is set but lacks bin/nvcc, whereas it used to fall
        # back to a PATH search. setup-cuda-hook only puts host-side (buildInputs)
        # deps in CUDAToolkit_ROOT, so cuda_nvcc (a nativeBuildInput) is missed and
        # the llama.cpp cuda_v12 runner's configure step dies with "CUDA Toolkit not
        # found". Mirror upstream fix NixOS/nixpkgs#545542 scoped to ollama: append
        # nvcc's root dir to CUDAToolkit_ROOT. This MUST run before ollama's own
        # `cmake -B build` (which is itself the derivation's preBuild), so prepend
        # rather than append — the parent build and its nested cuda_v12
        # ExternalProject both read CUDAToolkit_ROOT from the environment. Drop
        # once #545542 merges.
        ollama-cuda = prev.ollama-cuda.overrideAttrs (old: {
          preBuild = ''
            nvccExe="$(type -P nvcc)" && \
              addToSearchPathWithCustomDelimiter ";" CUDAToolkit_ROOT "''${nvccExe%/bin/nvcc}"
          ''
          + (old.preBuild or "");
        });
      };
  };
}
