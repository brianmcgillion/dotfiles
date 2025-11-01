# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Fail2ban intrusion prevention
#
# Configures fail2ban to protect services from brute-force attacks by monitoring
# logs and automatically banning IP addresses that show malicious behavior.
#
# Features:
# - Automatic IP banning after failed login attempts
# - Incremental ban time multipliers for repeat offenders
# - Ban time tracking across all jails
# - Maximum ban time of 1 week
#
# Configuration:
# - Max retries: 3 violations before ban
# - Initial ban time: 24 hours
# - Ban time multipliers: 1, 2, 4, 8, 16, 32, 64
# - Max ban time: 168 hours (1 week)
# - Overall jails: enabled (bans apply across all services)
#
# Usage:
#   features.security.fail2ban.enable = true;
#
# Enabled by default in: profile-server
#
# Protected services:
# - SSH (when sshd is enabled)
# - Any service writing to system logs
#
# Note: Requires services to log at appropriate verbosity levels.
# SSH should use LogLevel VERBOSE for optimal detection.
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.security.fail2ban;
in
{
  options.features.security.fail2ban = {
    enable = lib.mkEnableOption "fail2ban intrusion prevention";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      ignoreIP = [ ];
      bantime = "24h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
    };
  };
}
