# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# OpenCode terminal agent with the oh-my-openagent harness
#
# Both packages come from the llm-agents input rather than nixpkgs (see the
# overlay in packages/default.nix): nixpkgs lags OpenCode by a few patch
# releases, and oh-my-opencode is not in nixpkgs at all.
#
# Naming, because it is genuinely confusing: oh-my-opencode and
# oh-my-openagent are the same product. Upstream renamed itself when it grew
# Codex support and dual-publishes both names on npm; llm-agents still
# packages the old one, and the binary it ships is `oh-my-opencode` -- so the
# installer is `oh-my-opencode install`, even though upstream docs say
# `oh-my-openagent install`. (`omo` was removed this major version.)
# The plugin entry in opencode.json is `oh-my-openagent`, and runtime config
# lives in ~/.omo/omo.jsonc. `oh-my-codex` is an unrelated project.
#
# This module installs the binaries and stops there. A working setup still
# needs a once-per-user `oh-my-opencode install`, which registers the plugin
# in opencode.json and walks subscription detection, an 11-agent model matrix
# and per-provider authentication -- none of which is reproducible from
# config, so pretending otherwise would only fight the installer for
# ownership of opencode.json.
#
# Usage:
#   features.ai.opencode.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.ai.opencode;
in
{
  options.features.ai.opencode = {
    enable = lib.mkEnableOption "OpenCode terminal agent with the oh-my-openagent harness";

    telemetry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to leave upstream's anonymous telemetry enabled. It sends one
        PostHog "daily active" event per machine per UTC day, keyed by a
        SHA256 hash of the install id rather than the hostname.

        Off by default here: it is on upstream, and the environment variables
        that disable it are the one part of this tool's setup that config can
        express, so express it. Set true to restore upstream behaviour.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.opencode
      pkgs.oh-my-opencode
    ];

    # Both spellings: the plugin reads OMO_SEND_ANONYMOUS_TELEMETRY, the
    # Codex-side components read OMO_DISABLE_POSTHOG.
    environment.variables = lib.mkIf (!cfg.telemetry) {
      OMO_DISABLE_POSTHOG = "1";
      OMO_SEND_ANONYMOUS_TELEMETRY = "0";
    };
  };
}
