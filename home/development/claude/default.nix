# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Claude Code CLI configuration
#
# Deployed as read-only nix-store symlinks.
# To update: edit these files, run `nix fmt && sudo nixos-rebuild switch`.
# Runtime commands like `claude config set` or `claude mcp add` are
# intentionally blocked — nix is the source of truth.
#
# Plugin management:
# - enabledPlugins in settings.json controls which plugins are active
# - Third-party marketplaces listed below are auto-registered on activation
# - All enabled plugins are auto-installed on activation (idempotent)
{ pkgs, lib, ... }:
let
  # Third-party plugin marketplaces (GitHub repos).
  # Official marketplace (anthropics/claude-plugins-official) is built-in.
  thirdPartyMarketplaces = [
    "poemswe/co-researcher"
  ];

  pluginSyncScript = pkgs.writeShellApplication {
    name = "claude-plugin-sync";
    runtimeInputs = [
      pkgs.claude-code
      pkgs.jq
    ];
    text = ''
      # Skip if claude binary is not yet available (first bootstrap)
      if ! command -v claude &>/dev/null; then
        echo "claude-plugin-sync: claude not found, skipping"
        exit 0
      fi

      # Register third-party marketplaces (idempotent, skips if already known)
      # shellcheck disable=SC2043
      for repo in ${lib.concatStringsSep " " thirdPartyMarketplaces}; do
        claude plugin marketplace add "$repo" 2>/dev/null || true
      done

      # Read enabled plugins from the nix-managed settings and install any missing
      jq -r '.enabledPlugins // {} | keys[]' \
        ${./settings.json} | while read -r plugin; do
        if ! claude plugin list 2>/dev/null | grep -q "$plugin"; then
          claude plugin install "$plugin" 2>/dev/null || true
        fi
      done
    '';
  };
in
{
  home.file = {
    ".config/claude/settings.json".source = ./settings.json;
    ".config/claude/statusline-command.sh" = {
      source = ./statusline-command.sh;
      executable = true;
    };
  };

  # Sync plugins on activation: register marketplaces, install missing plugins.
  home.activation.claudePluginSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${lib.getExe pluginSyncScript}
  '';

  # Clean up ~/.claude.json.backup.* files that Claude Code hardcodes to $HOME.
  # Upstream bug: https://github.com/anthropics/claude-code/issues/1455
  systemd.user.services.claude-backup-cleanup = {
    Unit.Description = "Clean up Claude Code backup file pollution in $HOME";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.findutils}/bin/find %h -maxdepth 1 -name '.claude.json.backup.*' -delete";
    };
  };
  systemd.user.timers.claude-backup-cleanup = {
    Unit.Description = "Daily cleanup of Claude Code backup files";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
