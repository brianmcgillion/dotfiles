{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my-nebula-network;

  #TODO: hardcode pantheon for now
  #make a submodule for thisf
  lighthouses = if cfg.isLightHouse then [ ] else [ "10.99.99.1" ];
  port = 4242;
  hostMap = {
    "10.99.99.1" = [ "95.217.167.39:${toString port}" ];
  };
  networkName = "pantheon";
  defaultOwner = config.systemd.services."nebula@${networkName}".serviceConfig.User or "root";
in
{
  options.my-nebula-network = {
    enable = lib.mkEnableOption "Enable Nebula network";
    isLightHouse = lib.mkEnableOption "Is this node a lighthouse?";
    nebula-hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Hostname on the nebula network";
    };
    cert = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the certificate file";
    };
    key = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the key file";
    };
    ca = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the ca file";
    };
    configOwner = lib.mkOption {
      type = lib.types.str;
      default = defaultOwner;
      description = "Owner of the nebula config file";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      environment.systemPackages = [ pkgs.nebula ];

      services.nebula.networks = {
        "${networkName}" = {
          enable = true;
          isLighthouse = cfg.isLightHouse;
          inherit (cfg) cert;
          inherit (cfg) key;
          inherit (cfg) ca;

          inherit lighthouses;

          settings =
            if cfg.isLightHouse then
              {
                lighthouse = {
                  serve_dns = true;
                  dns = {
                    listen = "10.99.99.1";
                    port = 53;
                  };
                };
              }
            else
              { };

          tun.device = networkName;
          staticHostMap = hostMap;

          firewall = {
            outbound = [
              {
                host = "any";
                port = "any";
                proto = "any";
              }
            ];
            inbound =
              [
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
              ++ (lib.optionals cfg.isLightHouse [
                {
                  port = 53;
                  proto = "udp";
                  group = "any";
                }
              ]);
          };
        };
      };
    })

    (lib.mkIf cfg.isLightHouse {
      #TODO: tmp until https://github.com/NixOS/nixpkgs/pull/292016 is merged
      systemd.services."nebula@${networkName}".serviceConfig = {
        CapabilityBoundingSet = lib.mkForce "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
        AmbientCapabilities = lib.mkForce "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
      };
      # allow nebula to claim port 53 from systemd-resolved
      services.resolved.extraConfig = ''
        DNSStubListener=no
      '';
      # open the systems firewall for DNS only on the nebula interface
      networking.firewall.interfaces."${networkName}".allowedUDPPorts = [ 53 ];
    })
  ];
}
