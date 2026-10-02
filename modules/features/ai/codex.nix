# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# OpenAI Codex CLI and the Codex desktop app
#
# Both come from the llm-agents input rather than nixpkgs (see the overlay in
# packages/default.nix): nixpkgs trails the CLI by a few patch releases, and
# its `chatgpt` attribute is aarch64-darwin only, so on Linux there is no
# nixpkgs desktop build to pick.
#
# Naming: there is no `codex-desktop`. OpenAI ships Codex inside the ChatGPT
# desktop app, so the package and the binary it installs are both `chatgpt`.
#
# The app is unfree, and its derivation only half-pins it: on first launch it
# downloads a `codex-primary-runtime` of its own, which the llm-agents wrapper
# patchelfs in place via an inotify watcher. The app's Codex therefore updates
# out from under Nix; the CLI below does not.
#
# Usage:
#   features.ai.codex.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.ai.codex;
in
{
  options.features.ai.codex = {
    enable = lib.mkEnableOption "OpenAI Codex CLI";

    desktop = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to also install the Codex desktop app (the `chatgpt`
        package). It pulls a 2.7 GiB unfree Electron closure carrying both
        Qt5 and Qt6 shims, so set false on hosts that only want the
        terminal agent.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.codex
    ]
    ++ lib.optional cfg.desktop pkgs.chatgpt;
  };
}
