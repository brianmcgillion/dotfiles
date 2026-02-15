# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# AI/ML tooling with Ollama and Goose
#
# Provides local LLM inference via Ollama with optional GPU acceleration
# and AI coding tools via goose-cli.
#
# Features:
# - Ollama LLM inference server (systemd service)
# - GPU acceleration (CUDA for NVIDIA, ROCm for AMD)
# - Model preloading configuration
# - Goose CLI AI coding agent
#
# Usage:
#   features.ai.enable = true;
#   features.ai.ollama.models = [ "llama3.2:3b" ];
#
# GPU acceleration is auto-detected from hardware.nvidia.modesetting.enable.
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
    enable = lib.mkEnableOption "AI/ML tooling with Ollama and Goose";

    ollama = {
      acceleration = lib.mkOption {
        type = lib.types.enum [
          "cuda"
          "rocm"
          "cpu"
        ];
        default = if config.hardware.nvidia.modesetting.enable or false then "cuda" else "cpu";
        defaultText = lib.literalExpression ''
          if config.hardware.nvidia.modesetting.enable or false then "cuda" else "cpu"
        '';
        description = ''
          GPU acceleration backend for Ollama. Selects the appropriate
          ollama package variant (ollama-cuda, ollama-rocm, ollama-cpu).
          Auto-detects NVIDIA via hardware.nvidia.modesetting.enable.
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
    };

    environment.systemPackages = [
      pkgs.goose-cli
      pkgs.ollama
      pkgs.nvtopPackages.full
    ];

    environment.sessionVariables = {
      OLLAMA_HOST = "http://127.0.0.1:11434";
    };

  };
}
