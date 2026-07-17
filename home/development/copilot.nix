# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# GitHub Copilot CLI configuration
#
# The MCP server list is generated from the shared catalog in
# ./mcp-servers.nix so it cannot drift from the Claude Code registrations.
{
  config,
  lib,
  ...
}:
let
  catalog = import ./mcp-servers.nix { inherit (config.home) homeDirectory; };

  toCopilot =
    server:
    if server ? transport && server.transport == "http" then
      {
        type = "http";
        inherit (server) url;
        tools = [ "*" ];
      }
    else
      {
        type = "local";
        inherit (server) command args;
        tools = [ "*" ];
      };

  copilotServers = lib.mapAttrs (_: toCopilot) (
    lib.filterAttrs (_: server: server.copilot or true) catalog
  );
in
{
  home.file.".config/.copilot/mcp-config.json".text = builtins.toJSON {
    mcpServers = copilotServers;
  };
}
