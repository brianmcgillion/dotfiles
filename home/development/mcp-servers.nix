# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# Single source of truth for MCP server definitions.
#
# Consumed by:
# - home/development/claude/default.nix  -> `claude mcp add` registrations
# - home/development/copilot.nix         -> ~/.config/.copilot/mcp-config.json
#
# Entry shape:
#   <name> = {
#     command = "npx"; args = [ ... ];      # stdio servers
#     # or: transport = "http"; url = ...;  # http servers
#     claude = false;   # optional: skip for Claude Code (default true)
#     copilot = false;  # optional: skip for Copilot CLI (default true)
#   };
{ homeDirectory }:
{
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
      "${homeDirectory}/projects"
      "${homeDirectory}/.dotfiles"
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
      "${homeDirectory}/Documents/Papers/arxiv"
    ];
  };

  # Saleae Logic 2 automation bridge
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
    copilot = false; # OAuth flow is only wired up through Claude Code
  };

  # Claude Code gets serena and context7 via plugins instead.
  serena = {
    command = "uvx";
    args = [
      "--from"
      "git+https://github.com/oraios/serena"
      "serena"
      "start-mcp-server"
      "--context"
      "desktop-app"
    ];
    claude = false;
  };

  context7 = {
    command = "npx";
    args = [
      "-y"
      "@upstash/context7-mcp@latest"
    ];
    claude = false;
  };
}
