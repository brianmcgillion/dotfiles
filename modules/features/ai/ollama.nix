# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Ollama local LLM inference server
#
# One feature under the features.ai.* namespace; further AI modules get
# their own file beside this one.
#
# Features:
# - Ollama LLM inference server (systemd service)
# - GPU acceleration (CUDA for NVIDIA, ROCm for AMD)
# - Model preloading configuration
#
# Usage:
#   features.ai.ollama.enable = true;   # models/derivedModels default below
#
# The model set lives here rather than in a host config: it is tuned to
# one GPU budget and is not a per-host decision. Override models or
# derivedModels on a host with different VRAM.
#
# GPU acceleration is auto-detected from the NVIDIA driver being loaded
# (services.xserver.videoDrivers, set by modules/hardware/nvidia.nix).
# Override with: features.ai.ollama.acceleration = "cuda" / "rocm" / "cpu";
#
# Used by: argus (NVIDIA RTX 5090 desktop, 32 GB VRAM)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.ai.ollama;
in
{
  options.features.ai.ollama = {
    enable = lib.mkEnableOption "Ollama local LLM inference server";

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
      # Both bases are pulled only so the derivedModels below resolve them
      # locally -- use the derived names, never these tags, which carry no
      # num_ctx and would load at the server-wide 131072.
      default = [
        # keep-sorted start
        "hf.co/OBLITERATUS/Qwen3.8-27B-OBLITERATED:Q8_0"
        "huihui_ai/Qwen3.8-abliterated:27b-q6_K"
        # keep-sorted end
      ];
      example = [
        "llama3.2:3b"
        "codellama:13b"
      ];
      description = "List of Ollama models to preload on activation.";
    };

    derivedModels = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.str;
              example = "hf.co/user/repo:Q8_0";
              description = ''
                Base model the derivative is built on. Pull it via
                `models` as well, so the reference resolves locally
                instead of being fetched again at create time.
              '';
            };
            parameters = lib.mkOption {
              type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.int);
              default = { };
              example = {
                num_ctx = 32768;
              };
              description = "PARAMETER lines baked into the Modelfile.";
            };
          };
        }
      );
      # Sized for argus (RTX 5090, 32 GB VRAM). A host with a smaller
      # card should override rather than inherit these.
      default = {
        "qwen3.8-obliterated" = {
          from = "hf.co/OBLITERATUS/Qwen3.8-27B-OBLITERATED:Q8_0";
          parameters = {
            # Measured, not estimated: ollama reports a 31 GB working set
            # at 32768 and spills 7% to CPU; 16384 fits at 100% GPU in
            # 28 GB. The weights+KV sum understates it -- compute buffers
            # and the CUDA context are not in that figure. Do not raise
            # without re-measuring.
            num_ctx = 16384;
            # The model card warns quality "degrades significantly" above 0.5.
            temperature = "0.4";
          };
        };

        "qwen3.8-claude-code" = {
          from = "huihui_ai/Qwen3.8-abliterated:27b-q6_K";
          # Unverified until the pull completes -- confirm with
          # `ollama ps` that it reads 100% GPU, and lower if it does not.
          parameters.num_ctx = 65536;
        };
      };
      description = ''
        Local models created from a generated Modelfile, for per-model
        settings the server-wide environment cannot express -- chiefly
        num_ctx, since OLLAMA_CONTEXT_LENGTH applies to every model at
        once and a large model may not have the VRAM for it.

        Created by the ollama-derived-models unit after the base has
        finished downloading.

        Do not enable services.ollama.syncModels alongside this: it
        deletes any installed model absent from loadModels, which is
        exactly what these are.
      '';
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
        .${cfg.acceleration};
      loadModels = cfg.models;
      user = "ollama";
      group = "ollama";
      environmentVariables = {
        # Server-wide default context length (OLLAMA_NUM_CTX is not a
        # recognized server variable; num_ctx is per-request only).
        OLLAMA_CONTEXT_LENGTH = "131072";
        # Ollama evicts an idle model after 5 minutes by default, and
        # reloading a ~28 GB model costs several seconds. Hold it longer so a
        # short pause mid-session does not pay that again. Not "-1": that
        # pins the weights indefinitely, which on a 32 GB card leaves nothing
        # for anything else.
        OLLAMA_KEEP_ALIVE = "30m";
      };
    };

    systemd.services.ollama.serviceConfig.UMask = lib.mkForce "0027";

    systemd.services.ollama-derived-models = lib.mkIf (cfg.derivedModels != { }) {
      description = "Create local Ollama models from generated Modelfiles";
      wantedBy = [ "multi-user.target" ];
      after = [
        "ollama.service"
        "ollama-model-loader.service"
      ];
      bindsTo = [ "ollama.service" ];
      # Same environment as the server, so OLLAMA_HOST points at it.
      environment = config.systemd.services.ollama.environment;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        # The base model may be tens of GB; the create waits for that pull.
        TimeoutStartSec = "infinity";
      };
      script =
        let
          ollama = lib.getExe config.services.ollama.package;
          mkModelfile =
            name: m:
            pkgs.writeText "Modelfile-${name}" (
              lib.concatStringsSep "\n" (
                [ "FROM ${m.from}" ] ++ lib.mapAttrsToList (k: v: "PARAMETER ${k} ${toString v}") m.parameters
              )
              + "\n"
            );
          create = name: m: ''
            # ollama-model-loader is Type=exec, so systemd reports it active
            # while the pull is still running -- After= alone guarantees
            # nothing. Wait for the base to actually land (2h ceiling).
            for _ in $(seq 1 720); do
              if '${ollama}' list | grep -qF ${lib.escapeShellArg m.from}; then
                break
              fi
              sleep 10
            done
            '${ollama}' create ${lib.escapeShellArg name} -f ${mkModelfile name m}
          '';
        in
        lib.concatStringsSep "\n" (lib.mapAttrsToList create cfg.derivedModels);
    };

    environment.systemPackages = [
      pkgs.nvtopPackages.full
    ];
  };
}
