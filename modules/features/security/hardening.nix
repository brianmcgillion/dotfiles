# SPDX-License-Identifier: MIT
# System security hardening
#
# Applies comprehensive system hardening configurations following security best practices.
# Includes kernel, network, and boot security enhancements.
#
# Features:
# - Kernel image protection (prevents runtime replacement)
# - Temporary filesystem hardening (/tmp on tmpfs, cleaned on boot)
# - Bootloader protection (disable editor to prevent boot parameter tampering)
# - SysRq key disabled (prevents low-level commands from console)
# - TCP hardening:
#   - IP spoofing mitigation (reverse path filtering)
#   - ICMP bogus error response filtering
#   - Source routing disabled
#   - ICMP redirect protection
#   - SYN flood protection (syncookies)
#   - TIME-WAIT assassination protection
# - TCP optimization:
#   - TCP Fast Open enabled
#   - BBR congestion control
#   - CAKE queue discipline for bufferbloat mitigation
# - ACME terms acceptance for TLS certificates
#
# Usage:
#   features.security.hardening.enable = true;
#
# Enabled by default in: profile-common (applies to all systems)
#
# Note: These settings prioritize security over compatibility.
# May need adjustment for specialized networking requirements.
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.security.hardening;
in
{
  options.features.security.hardening = {
    enable = lib.mkEnableOption "system hardening";
  };

  config = lib.mkIf cfg.enable {
    security.protectKernelImage = true;

    boot = {
      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
      };

      loader.systemd-boot.editor = false;

      kernel.sysctl = {
        "kernel.sysrq" = 0;

        # TCP hardening
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1;

        # TCP optimization
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "cake";
      };
      kernelModules = [ "tcp_bbr" ];
    };

    security.acme.acceptTerms = true;
  };
}
