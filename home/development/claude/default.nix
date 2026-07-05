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

  # User-scope MCP servers managed by nix.
  # Each entry maps server name to its CLI args for `claude mcp add --scope user`.
  # For HTTP servers, set transport = "http" and url instead of command/args.
  mcpServers = {
    binary-ninja-mcp = {
      command = "npx";
      args = [
        "-y"
        "binary-ninja-mcp"
        "--host"
        "localhost"
        "--port"
        "9009"
      ];
    };
    mcp-nixos = {
      command = "uvx";
      args = [ "mcp-nixos" ];
    };
    filesystem = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "/home/brian/projects"
        "/home/brian/.dotfiles"
      ];
    };
    sequential-thinking = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
    };
    mcp-dblp = {
      command = "uvx";
      args = [ "mcp-dblp" ];
    };
    arxiv-mcp-server = {
      command = "uv";
      args = [
        "tool"
        "run"
        "arxiv-mcp-server"
        "--storage-path"
        "/path/to/your/paper/storage"
      ];
    };
    logic2 = {
      transport = "http";
      url = "http://127.0.0.1:10530";
    };
    # Atlassian official remote MCP server (Jira/Confluence Cloud).
    # Cloud instance: tiicrypto.atlassian.net. Requires an interactive
    # OAuth login after activation: run `/mcp` in Claude Code, select
    # `atlassian`, and authenticate in the browser.
    atlassian = {
      transport = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
  };

  # Build `claude mcp add` commands from the mcpServers attrset.
  mcpAddCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: cfg:
      if cfg ? transport && cfg.transport == "http" then
        ''
          if ! claude mcp list 2>/dev/null | grep -q ${lib.escapeShellArg name}; then
            claude mcp add --scope user --transport http ${lib.escapeShellArg name} ${lib.escapeShellArg cfg.url} 2>/dev/null || true
          fi
        ''
      else
        let
          args = lib.concatStringsSep " " (map lib.escapeShellArg cfg.args);
        in
        ''
          if ! claude mcp list 2>/dev/null | grep -q ${lib.escapeShellArg name}; then
            claude mcp add --scope user ${lib.escapeShellArg name} -- ${lib.escapeShellArg cfg.command} ${args} 2>/dev/null || true
          fi
        ''
    ) mcpServers
  );

  pluginSyncScript = pkgs.writeShellApplication {
    name = "claude-plugin-sync";
    runtimeInputs = [
      pkgs.claude-code
      pkgs.jq
      pkgs.git
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

      # Ensure nix-managed MCP servers are registered
      ${mcpAddCommands}
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
