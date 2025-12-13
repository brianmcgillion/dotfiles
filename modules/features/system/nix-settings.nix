# SPDX-FileCopyrightText: 2024 Brian McGillion
# SPDX-License-Identifier: MIT
# Nix daemon settings with GitHub authentication
#
# Configures Nix access tokens for GitHub API authentication to avoid
# rate limiting when performing flake operations that query the GitHub API.
#
# Features:
# - GitHub Personal Access Token configuration for Nix
# - Per-user token support via SOPS encryption
# - Automatic service ordering (SOPS → Nix daemon)
# - Secure token storage with restrictive permissions
#
# Configuration:
#   features.system.nix-settings = {
#     enable = true;
#     githubToken = {
#       enable = true;
#       sopsFile = ./path-to-secrets.yaml;
#     };
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
# - Token stored as /run/secrets/github-token-ratelimit (mode 0440)
# - Only readable by root and keys group
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
  cfg = config.features.system.nix-settings;
in
{
  options.features.system.nix-settings = {
    enable = lib.mkEnableOption "Enhanced Nix settings with GitHub authentication";

    githubToken = {
      enable = lib.mkEnableOption "GitHub API token for avoiding rate limits";

      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the SOPS file containing the github-token-ratelimit secret.
          This allows per-user token configuration.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure GitHub access token for Nix to avoid rate limiting
    sops.secrets.github-token-ratelimit = lib.mkIf cfg.githubToken.enable {
      inherit (cfg.githubToken) sopsFile;
      mode = "0440";
      group = config.users.groups.keys.name;
    };

    nix.extraOptions = lib.mkIf cfg.githubToken.enable ''
      !include ${config.sops.templates."nix-access-tokens".path}
    '';

    sops.templates."nix-access-tokens" = lib.mkIf cfg.githubToken.enable {
      content = ''
        access-tokens = github.com=${config.sops.placeholder."github-token-ratelimit"}
      '';
      mode = "0440";
      group = config.users.groups.keys.name;
    };

    # Ensure the secret file is read before Nix daemon starts
    systemd.services.nix-daemon = lib.mkIf cfg.githubToken.enable {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
