# SPDX-License-Identifier: MIT
# Nebula overlay network
#
# Configures Nebula - a scalable overlay networking tool with a focus on performance,
# simplicity, and security. Nebula creates a private network between your hosts regardless
# of their physical location.
#
# Features:
# - Nebula network interface (pantheon)
# - Lighthouse or node mode configuration
# - Static host mapping for lighthouses
# - Firewall configuration with ICMP and SSH allowed
# - DNS service for lighthouse nodes (port 53)
# - mTLS certificate-based authentication
#
# Configuration:
#   features.networking.nebula = {
#     enable = true;
#     isLightHouse = false;  # true for lighthouse nodes
#     cert = "/path/to/cert.crt";
#     key = "/path/to/key.key";
#     ca = "/path/to/ca.crt";
#     staticHostMap = {
#       "10.99.99.1" = [ "external-ip:4242" ];
#     };
#   };
#
# Requirements:
# - Valid Nebula CA certificate
# - Node certificate signed by CA
# - Node private key
#
# Assertions:
# - Validates cert, key, and ca paths are set
# - Only applies lighthouse settings when both enabled and isLightHouse
#
# Network details:
# - Network name: pantheon
# - Lighthouse IP: 10.99.99.1
# - Port: 4242 (UDP)
# - DNS port: 53 (lighthouse only)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.features.networking.nebula;

  lighthouses = if cfg.isLightHouse then [ ] else [ "10.99.99.1" ];
  port = 4242;
  networkName = "pantheon";
  defaultOwner = config.systemd.services."nebula@${networkName}".serviceConfig.User or "root";
in
{
  options.features.networking.nebula = {
    enable = lib.mkEnableOption "Nebula overlay network";

    isLightHouse = lib.mkEnableOption "lighthouse mode";

    cert = lib.mkOption {
      type = lib.types.path;
      description = "Path to the certificate file";
    };

    key = lib.mkOption {
      type = lib.types.path;
      description = "Path to the key file";
    };

    ca = lib.mkOption {
      type = lib.types.path;
      description = "Path to the CA file";
    };

    configOwner = lib.mkOption {
      type = lib.types.str;
      default = defaultOwner;
      description = "Owner of the nebula config file";
    };

    staticHostMap = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        "10.99.99.1" = [ "95.217.167.39:${toString port}" ];
      };
      description = "Static host map for nebula lighthouse nodes";
      example = {
        "10.99.99.1" = [ "192.0.2.1:4242" ];
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.cert != null && cfg.cert != "";
          message = "features.networking.nebula.cert must be set when Nebula is enabled";
        }
        {
          assertion = cfg.key != null && cfg.key != "";
          message = "features.networking.nebula.key must be set when Nebula is enabled";
        }
        {
          assertion = cfg.ca != null && cfg.ca != "";
          message = "features.networking.nebula.ca must be set when Nebula is enabled";
        }
      ];

      environment.systemPackages = [ pkgs.nebula ];

      services.nebula.networks."${networkName}" = {
        enable = true;
        isLighthouse = cfg.isLightHouse;
        inherit (cfg) cert key ca;
        inherit lighthouses;

        settings = lib.mkIf cfg.isLightHouse {
          lighthouse = {
            serve_dns = true;
            dns = {
              listen = "10.99.99.1";
              port = 53;
            };
          };
        };

        tun.device = networkName;
        inherit (cfg) staticHostMap;

        firewall = {
          outbound = [
            {
              host = "any";
              port = "any";
              proto = "any";
            }
          ];
          inbound = [
            {
              host = "any";
              port = "any";
              proto = "icmp";
            }
            {
              host = "any";
              port = 22;
              proto = "tcp";
            }
          ]
          ++ lib.optionals cfg.isLightHouse [
            {
              port = 53;
              proto = "udp";
              group = "any";
            }
          ];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.isLightHouse) {
      systemd.services."nebula@${networkName}".serviceConfig = {
        CapabilityBoundingSet = lib.mkForce "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
        AmbientCapabilities = lib.mkForce "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      };
      services.resolved.extraConfig = ''
        DNSStubListener=no
      '';
      networking.firewall.interfaces."${networkName}".allowedUDPPorts = [ 53 ];
    })
  ];
}
