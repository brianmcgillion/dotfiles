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
# - DNS service for lighthouse nodes (port 53, overlay interface only)
# - mTLS certificate-based authentication
# - Optional sops wiring for the ca/key/cert secrets
#
# Configuration:
#   features.networking.nebula = {
#     enable = true;
#     isLighthouse = false;  # true for lighthouse nodes
#     useSopsSecrets = true; # wire ca/key/cert from sops.secrets.nebula-*
#     # ...or provide the paths explicitly:
#     # cert = "/path/to/cert.crt";
#     # key = "/path/to/key.key";
#     # ca = "/path/to/ca.crt";
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
# - Validates the derived interface name fits the kernel's 15-char limit
#
# Defaults:
# - Network name: pantheon
# - Lighthouse IP: 10.99.99.1
# - Port: 4242 (UDP) on the lighthouse; ephemeral on other nodes
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
  imports = [
    (lib.mkRenamedOptionModule
      [
        "features"
        "networking"
        "nebula"
        "isLightHouse"
      ]
      [
        "features"
        "networking"
        "nebula"
        "isLighthouse"
      ]
    )
  ];

  options.features.networking.nebula = {
    enable = lib.mkEnableOption "Nebula overlay network";

    isLighthouse = lib.mkEnableOption "lighthouse mode";

    useSopsSecrets = lib.mkEnableOption ''
      wiring ca/key/cert from the host's sops file. Declares
      sops.secrets.nebula-{ca,key,cert} (owned by the nebula service user)
      and uses their paths, so hosts only set sops.defaultSopsFile
    '';

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
        UDP port that the lighthouse listens on for peer connections.
        Non-lighthouse nodes use an ephemeral port (0): with punchy enabled
        roaming clients work fine without a fixed, firewall-opened port.
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

    # cert/key/ca have no defaults on purpose: if neither useSopsSecrets nor
    # an explicit path is given, evaluation fails with the module system's
    # "option ... is used but not defined" error naming the exact option.
    cert = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/host.crt";
      description = ''
        Path to the Nebula host certificate file (set automatically by
        useSopsSecrets). This certificate must be signed by the CA specified
        in the ca option.
        Generated using: nebula-cert sign -name "hostname" -ip "10.99.99.x/16"
      '';
    };

    key = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/host.key";
      description = ''
        Path to the Nebula host private key file (set automatically by
        useSopsSecrets). This key is generated alongside the certificate and
        must be kept secure. Permissions should be 0600 and owned by the
        nebula service user.
      '';
    };

    ca = lib.mkOption {
      type = lib.types.path;
      example = "/etc/nebula/ca.crt";
      description = ''
        Path to the Nebula Certificate Authority (CA) certificate file (set
        automatically by useSopsSecrets). All nodes in the Nebula network
        must share the same CA certificate.
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.useSopsSecrets {
        sops.secrets = {
          nebula-ca.owner = cfg.configOwner;
          nebula-key.owner = cfg.configOwner;
          nebula-cert.owner = cfg.configOwner;
        };

        features.networking.nebula = {
          ca = lib.mkDefault config.sops.secrets.nebula-ca.path;
          key = lib.mkDefault config.sops.secrets.nebula-key.path;
          cert = lib.mkDefault config.sops.secrets.nebula-cert.path;
        };
      })

      {
        assertions = [
          {
            # Interface names are limited to 15 bytes (IFNAMSIZ - 1); the
            # default "nebula.pantheon" is exactly at the limit.
            assertion = lib.stringLength "nebula.${cfg.networkName}" <= 15;
            message = "features.networking.nebula.networkName is too long: \"nebula.${cfg.networkName}\" exceeds the kernel's 15-character interface name limit";
          }
        ];

        # dig for overlay-DNS debugging comes from dnsutils in the base
        # system packages; only nebula itself is added here.
        environment.systemPackages = [ pkgs.nebula ];

        services.nebula.networks."${cfg.networkName}" = {
          enable = true;

          inherit (cfg) isLighthouse;
          inherit (cfg) cert key ca;
          lighthouses = if cfg.isLighthouse then [ ] else [ cfg.lighthouseAddress ];

          # run DNS server on the lighthouse
          lighthouse.dns = lib.mkIf cfg.isLighthouse {
            enable = true;
            # specify the internal interface to avoid conflicts with resolved
            host = cfg.lighthouseAddress;
            port = 53;
          };

          # Fixed port on the lighthouse (must be reachable at a known
          # address); ephemeral everywhere else so roaming clients don't
          # keep a permanently opened UDP port on untrusted networks.
          listen.port = if cfg.isLighthouse then cfg.listenPort else 0;

          inherit (cfg) staticHostMap;

          # https://nebula.defined.net/docs/config/punchy
          settings.punchy = {
            punch = true;
            respond = true;
          };

          # https://nebula.defined.net/docs/config/relay
          # Relay allows peers that cannot establish direct connections
          # (e.g., both behind NAT) to communicate through a relay node (the
          # lighthouse). The upstream module renders these typed options
          # into the relay block and enables use_relays itself.
          isRelay = cfg.isLighthouse;
          relays = if cfg.isLighthouse then [ ] else [ cfg.lighthouseAddress ];

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
            ++ lib.optionals cfg.isLighthouse [
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
            # (this also lets overlay peers reach the lighthouse DNS on the
            # tun interface — no public UDP 53 hole is needed, the DNS binds
            # the overlay address only)
            trustedInterfaces = [ "nebula.${cfg.networkName}" ];
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

        # The ExecStartPost hooks below hard-depend on resolvectl; without
        # resolved the nebula@ unit would fail in a restart loop.
        services.resolved.enable = lib.mkDefault true;

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
            "+${pkgs.systemd}/bin/resolvectl domain nebula.${cfg.networkName} ~${cfg.dnsDomain}"
          ];
        };
      }
    ]
  );
}
