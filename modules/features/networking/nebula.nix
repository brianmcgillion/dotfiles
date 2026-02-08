# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Nebula overlay network
#
# Configures Nebula - a scalable overlay networking tool with a focus on performance,
# simplicity, and security. Nebula creates a private network between your hosts regardless
# of their physical location.
#
# Features:
# - Nebula network interface (configurable name, default: pantheon)
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
#     # Optional: override network defaults
#     networkName = "pantheon";              # default
#     lighthouseAddress = "10.99.99.1";      # default
#     lighthousePublicAddress = "x.x.x.x";   # public IP of lighthouse
#     listenPort = 4242;                     # default
#     dnsDomain = "pantheon.bmg.sh";         # default
#     lighthouseHostname = "caelus";         # default
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
# Defaults:
# - Network name: pantheon
# - Lighthouse IP: 10.99.99.1
# - Port: 4242 (UDP)
# - DNS port: 53 (lighthouse only)
# - DNS domain: pantheon.bmg.sh
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.features.networking.nebula;

  defaultOwner = config.systemd.services."nebula@${cfg.networkName}".serviceConfig.User or "root";
in
{
  options.features.networking.nebula = {
    enable = lib.mkEnableOption "Nebula overlay network";

    isLightHouse = lib.mkEnableOption "lighthouse mode";

    networkName = lib.mkOption {
      type = lib.types.str;
      default = "pantheon";
      description = ''
        Name of the Nebula network. Used for interface naming and service identification.
      '';
    };

    lighthouseAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.99.99.1";
      example = "10.0.0.1";
      description = ''
        Internal Nebula IP address of the lighthouse node.
        All non-lighthouse nodes will use this address for discovery.
      '';
    };

    lighthousePublicAddress = lib.mkOption {
      type = lib.types.str;
      default = "95.217.167.39";
      example = "203.0.113.10";
      description = ''
        Public IP address of the lighthouse node.
        Used in the default staticHostMap for initial discovery.
      '';
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 4242;
      description = ''
        UDP port that Nebula listens on for peer connections.
      '';
    };

    dnsDomain = lib.mkOption {
      type = lib.types.str;
      default = "pantheon.bmg.sh";
      example = "nebula.example.com";
      description = ''
        DNS domain for the Nebula network.
        Used for split-horizon DNS configuration on the interface.
      '';
    };

    lighthouseHostname = lib.mkOption {
      type = lib.types.str;
      default = "caelus";
      description = ''
        Hostname of the lighthouse node for static hosts entry.
      '';
    };

    cert = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/host.crt";
      description = ''
        Path to the Nebula host certificate file.
        This certificate must be signed by the CA specified in the ca option.
        Generated using: nebula-cert sign -name "hostname" -ip "10.99.99.x/16"
      '';
    };

    key = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/host.key";
      description = ''
        Path to the Nebula host private key file.
        This key is generated alongside the certificate and must be kept secure.
        Permissions should be 0600 and owned by the nebula service user.
      '';
    };

    ca = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/ca.crt";
      description = ''
        Path to the Nebula Certificate Authority (CA) certificate file.
        All nodes in the Nebula network must share the same CA certificate.
        Generated using: nebula-cert ca -name "Organization Name"
      '';
    };

    configOwner = lib.mkOption {
      type = lib.types.str;
      default = defaultOwner;
      example = "nebula";
      description = ''
        Owner of the Nebula configuration file.
        Defaults to the user running the nebula systemd service.
        Must have read access to cert, key, and ca files.
      '';
    };

    staticHostMap = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        "${cfg.lighthouseAddress}" = [ "${cfg.lighthousePublicAddress}:${toString cfg.listenPort}" ];
      };
      example = {
        "10.99.99.1" = [
          "192.0.2.1:4242"
          "198.51.100.1:4242"
        ];
        "10.99.99.2" = [ "203.0.113.10:4242" ];
      };
      description = ''
        Static mappings of Nebula IP addresses to public internet addresses.
        Used to initially contact lighthouse nodes before using the Nebula network for discovery.
        Format: { "nebula-ip" = [ "public-ip:port" ... ]; }
        Multiple public addresses can be specified for redundancy.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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

    environment.systemPackages = [
      pkgs.nebula
      pkgs.dig
    ];

    services.nebula.networks."${cfg.networkName}" = {
      enable = true;

      isLighthouse = cfg.isLightHouse;
      inherit (cfg) cert key ca;
      lighthouses = if cfg.isLightHouse then [ ] else [ cfg.lighthouseAddress ];

      # run DNS server on the lighthouse
      lighthouse.dns = lib.mkIf cfg.isLightHouse {
        enable = true;
        # specify the internal interface to avoid conflicts with resolved
        host = cfg.lighthouseAddress;
        port = 53;
      };

      listen.port = cfg.listenPort;

      inherit (cfg) staticHostMap;

      # https://nebula.defined.net/docs/config/punchy
      settings.punchy = {
        punch = true;
        respond = true;
      };

      # https://nebula.defined.net/docs/config/relay
      # Relay allows peers that cannot establish direct connections (e.g., both behind NAT)
      # to communicate through a relay node (the lighthouse in this case)
      settings.relay = {
        # Lighthouse acts as a relay for other nodes
        am_relay = cfg.isLightHouse;
        # Non-lighthouse nodes use the lighthouse as a relay when direct connection fails
        relays = if cfg.isLightHouse then [ ] else [ cfg.lighthouseAddress ];
        # Enable using relays for all nodes
        use_relays = true;
      };

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
            host = "any";
          }
        ];
      };
    };

    networking = {
      firewall = {
        # don't stack nixos firewall on top of the nebula firewall
        trustedInterfaces = [ "nebula.${cfg.networkName}" ];
        # globally open port 53 to serve DNS
        allowedUDPPorts = lib.mkIf cfg.isLightHouse [ 53 ];
      };

      # Static hosts entry for the lighthouse
      # Nebula's DNS only resolves hosts that have connected to the lighthouse,
      # but the lighthouse never connects to itself, so it won't be in the hostmap.
      # This provides a static fallback for resolving the lighthouse hostname.
      # Include both FQDN and short name for convenience.
      hosts = {
        "${cfg.lighthouseAddress}" = [
          "${cfg.lighthouseHostname}.${cfg.dnsDomain}"
          cfg.lighthouseHostname
        ];
      };
    };

    # Configure per-link DNS for the Nebula interface using resolvectl
    # This works regardless of whether systemd-networkd or NetworkManager manages networking
    # After Nebula creates the interface, we configure:
    # - DNS server pointing to the lighthouse
    # - Routing domain (~<dnsDomain>) so only Nebula queries go to lighthouse
    # Note: '+' prefix runs the command with full privileges (root) since resolvectl
    # requires elevated permissions to modify DNS configuration
    systemd.services."nebula@${cfg.networkName}".serviceConfig = {
      ExecStartPost = [
        "+${pkgs.systemd}/bin/resolvectl dns nebula.${cfg.networkName} ${cfg.lighthouseAddress}"
        "+${pkgs.systemd}/bin/resolvectl domain nebula.${cfg.networkName} ${cfg.dnsDomain}"
      ];
    };
  };
}
