# SPDX-License-Identifier: MIT
# SSH server with hardened configuration
#
# Configures OpenSSH server with security-focused settings.
# Automatically enables fail2ban protection when enabled.
#
# Features:
# - Password authentication disabled (key-only)
# - Keyboard-interactive authentication disabled
# - Client keepalive (60 second interval)
# - Verbose logging for fail2ban integration
# - Ed25519 host key only (modern, secure)
# - Automatic fail2ban integration
#
# Usage:
#   features.security.sshd.enable = true;
#
# Enabled by default in: profile-server
# Available but not enabled in: profile-client
#
# Security notes:
# - Only SSH key authentication is allowed
# - Root login configuration is not forced (can be set per-host)
# - Verbose logging is required for fail2ban to detect attacks
# - Ed25519 provides better security and performance than RSA
#
# Dependencies:
# - Automatically enables features.security.fail2ban
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.security.sshd;
in
{
  options.features.security.sshd = {
    enable = lib.mkEnableOption "SSH server with hardened configuration";
  };

  config = lib.mkIf cfg.enable {
    features.security.fail2ban.enable = lib.mkDefault true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        ClientAliveInterval = lib.mkDefault 60;
        LogLevel = "VERBOSE";
      };
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
