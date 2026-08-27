# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Local LLM inference toolchain. Entered from anywhere with `dev ai`.
#
# Exists so the heavy CUDA engines are built (or substituted) on demand rather
# than sitting in every host's system closure. FreeToken in particular drags an
# unfree CUDA 13 toolkit behind it, which no host should pay for just to have
# `ft` on PATH -- hence `features.ai.freetoken` stays off and this shell is the
# way in. See packages/misc/freetoken in seclab-pkgs for why it is FHS-wrapped.

#
# Models are fetched on demand, deliberately.
#
# NVIDIA-only, like both engines: ollama-cuda and freetoken are the CUDA builds.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.ai = {
        devshell = {
          name = "ai";
          meta.description = "Local LLM inference: ollama, freetoken, model fetching";
          packages = [
            # keep-sorted start
            pkgs.freetoken
            pkgs.nvtopPackages.full
            pkgs.ollama-cuda
            pkgs.python3Packages.huggingface-hub
            # keep-sorted end
          ];
        };

        env = [
          # FreeToken has no preload step: `ft serve --model <hf-repo-id>` calls
          # snapshot_download() lazily on first run, with no cache_dir, so
          # weights would default to ~/.cache/huggingface.
          {
            name = "HF_HOME";
            eval = "\${XDG_DATA_HOME:-$HOME/.local/share}/huggingface";
          }

          # Mirrors the ollama service's own settings (modules/features/ai/ollama.nix)
          # so a CLI-launched `ollama serve` behaves like argus's does rather
          # than silently falling back to ollama's much smaller defaults.
          {
            name = "OLLAMA_CONTEXT_LENGTH";
            value = "131072";
          }
          {
            name = "OLLAMA_KEEP_ALIVE";
            value = "30m";
          }
        ];
      };
    };
}
