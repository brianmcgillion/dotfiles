# SPDX-FileCopyrightText: 2024 Brian McGillion
# SPDX-License-Identifier: MIT
# GitHub API token for Nix flake operations
#
# Configures a Nix access token for GitHub API authentication to avoid
# rate limiting when performing flake operations that query the GitHub API.
#
# Features:
# - GitHub Personal Access Token configuration for Nix
# - Per-user token support via SOPS encryption
# - Automatic service ordering (SOPS → Nix daemon)
#
# Configuration:
#   features.system.github-token = {
#     enable = true;
#     sopsFile = ./path-to-secrets.yaml;
#   };
#
# The SOPS file must contain a 'github-token-ratelimit' secret with your
# GitHub Personal Access Token. No scopes/permissions are required - the
# token only needs to be valid to get higher rate limits for unauthenticated
# API access.
#
# Usage:
#   Typically configured per-user in user modules (e.g., modules/users/brian/default.nix)
#   rather than enabled globally, since GitHub tokens are user-specific.
#
# Enabled by default in: None (must be explicitly enabled per-user)
#
# Security notes:
# - Raw token secret: /run/secrets/github-token-ratelimit (mode 0440, root:keys)
# - Rendered access-tokens file: mode 0400, owned by the configured owner
#   (the nix daemon runs as root and can always read it)
# - No GitHub scopes required (increases unauthenticated rate limits only)
# - Per-user SOPS files allow each user their own token
#
# Rate limits:
# - Without token: 60 requests/hour per IP
# - With token: 5,000 requests/hour per user
#
# Example SOPS secret:
#   github-token-ratelimit: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#
# References:
# - https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-access-tokens
# - https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.system.github-token;
in
{
  options.features.system.github-token = {
    enable = lib.mkEnableOption "GitHub API token for avoiding rate limits";

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the SOPS file containing the github-token-ratelimit secret.
        This allows per-user token configuration.
      '';
    };

    owner = lib.mkOption {
      type = lib.types.str;
      default = "root";
      example = "brian";
      description = ''
        User that owns the rendered access-tokens file. The file is !include'd
        from nix.conf, which nix *clients* parse too — set this to the user
        who runs nix commands so their evaluations can use the token.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure GitHub access token for Nix to avoid rate limiting
    sops.secrets.github-token-ratelimit = {
      inherit (cfg) sopsFile;
      mode = "0440";
      group = config.users.groups.keys.name;
    };

    nix.extraOptions = ''
      !include ${config.sops.templates."nix-access-tokens".path}
    '';

    sops.templates."nix-access-tokens" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder."github-token-ratelimit"}
      '';
      # Readable by the owning user (nix client) only; the root-run nix
      # daemon reads it regardless. Never 0444 — that leaks the token to
      # every local user.
      inherit (cfg) owner;
      mode = "0400";
    };

    # Ensure the secret file is read before Nix daemon starts
    systemd.services.nix-daemon = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
