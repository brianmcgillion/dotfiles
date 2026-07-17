# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# AI/ML tooling with Ollama
#
# Provides local LLM inference via Ollama with optional GPU acceleration.
#
# Features:
# - Ollama LLM inference server (systemd service)
# - GPU acceleration (CUDA for NVIDIA, ROCm for AMD)
# - Model preloading configuration
#
# Usage:
#   features.ai.enable = true;
#   features.ai.ollama.models = [ "llama3.2:3b" ];
#
# GPU acceleration is auto-detected from the NVIDIA driver being loaded
# (services.xserver.videoDrivers, set by modules/hardware/nvidia.nix).
# Override with: features.ai.ollama.acceleration = "cuda" / "rocm" / "cpu";
#
# Used by: argus (NVIDIA RTX 5080 desktop)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.ai;
in
{
  options.features.ai = {
    enable = lib.mkEnableOption "AI/ML tooling with Ollama";

    ollama = {
      acceleration = lib.mkOption {
        type = lib.types.enum [
          "cuda"
          "rocm"
          "cpu"
        ];
        # hardware.nvidia.modesetting.enable is unsuitable for detection:
        # its default is version-derived and effectively true on every host.
        # The videoDrivers entry is only present when hardware-nvidia is used.
        default = if lib.elem "nvidia" (config.services.xserver.videoDrivers or [ ]) then "cuda" else "cpu";
        defaultText = lib.literalExpression ''
          if lib.elem "nvidia" (config.services.xserver.videoDrivers or [ ]) then "cuda" else "cpu"
        '';
        description = ''
          GPU acceleration backend for Ollama. Selects the appropriate
          ollama package variant (ollama-cuda, ollama-rocm, ollama-cpu).
          Auto-detects NVIDIA via services.xserver.videoDrivers.
        '';
      };

      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "llama3.2:3b"
          "codellama:13b"
        ];
        description = "List of Ollama models to preload on activation.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package =
        {
          cuda = pkgs.ollama-cuda;
          rocm = pkgs.ollama-rocm;
          cpu = pkgs.ollama-cpu;
        }
        .${cfg.ollama.acceleration};
      loadModels = cfg.ollama.models;
      user = "ollama";
      group = "ollama";
      environmentVariables = {
        # Server-wide default context length (OLLAMA_NUM_CTX is not a
        # recognized server variable; num_ctx is per-request only).
        OLLAMA_CONTEXT_LENGTH = "131072";
      };
    };

    systemd.services.ollama.serviceConfig.UMask = lib.mkForce "0027";

    environment.systemPackages = [
      pkgs.nvtopPackages.full
    ];
  };
}
