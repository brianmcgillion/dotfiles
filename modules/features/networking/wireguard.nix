# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# WireGuard client tunnels
#
# Declares any number of wg-quick tunnels per host and wires their keys from
# the host's sops file, so hosts state only what is actually host-specific
# (which network, which address).
#
# Two layers:
# - networks.<name>: catalog of known VPNs (peers + DNS). The shared personal
#   VPN ("bmg-vps") ships as a default here so its peer key/endpoint lives in
#   exactly one place instead of being copied into every host.
# - tunnels.<name>: one wg-quick interface. Reference a catalog network,
#   and/or give peers of its own.
#
# Keys are named by their *sops secret name* (privateKeySecret /
# presharedKeySecret), not by path — the module declares the secrets against
# the host's sops.defaultSopsFile and fills in the paths.
#
# Usage:
#   features.networking.wireguard = {
#     enable = true;
#     tunnels.wg0 = {
#       network = "bmg-vps";
#       address = [ "10.7.0.4/24" ];
#     };
#   };
#
# A tunnel to somewhere else entirely (own peer, own key, split routing):
#   features.networking.wireguard.tunnels.wg1 = {
#     address = [ "10.8.0.2/24" ];
#     privateKeySecret = "wg1-privateKeyFile";
#     peers = [
#       {
#         publicKey = "...";
#         endpoint = "vpn.example.com:51820";
#         allowedIPs = [ "10.8.0.0/24" ];
#       }
#     ];
#   };
#
# Anything this module does not model (mtu, table, listenPort, postUp, ...)
# can be set on the generated interface directly from the host — both write
# networking.wg-quick.interfaces, so the module system merges them:
#   networking.wg-quick.interfaces.wg0.mtu = 1380;
#
# Tunnels do not autostart by default; bring one up with: wg-quick up wg0
#
# Enabled by default in: none (opt-in per host; module imported by profile-client)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.networking.wireguard;

  peerOpts = {
    options = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        example = "3xZ1Ug4n8XrjZqlrrrveiIPQq3uyMtxuJXII3vCwyww=";
        description = "Base64 public key of the peer.";
      };

      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = [ "10.8.0.0/24" ];
        description = ''
          Routes directed at this peer. Deliberately has no default: use
          [ "0.0.0.0/0" ] for a full tunnel, or list the specific subnets
          for a split tunnel — the choice should be explicit.
        '';
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "vpn.example.com:51820";
        description = "Peer address as host:port. Null for peers that only connect inbound.";
      };

      persistentKeepalive = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 25;
        description = "Seconds between keepalive packets; needed behind NAT.";
      };

      presharedKeySecret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "wg-presharedKeyFile";
        description = ''
          Name of the sops secret holding this peer's preshared key
          (resolved against the host's sops.defaultSopsFile). Null when the
          peer uses no preshared key.
        '';
      };
    };
  };

  networkOpts = {
    options = {
      peers = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule peerOpts);
        description = "Peers that make up this network.";
      };

      dns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "172.26.0.2" ];
        description = "DNS servers to use while a tunnel to this network is up.";
      };
    };
  };

  tunnelOpts = {
    options = {
      network = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "bmg-vps";
        description = ''
          Name of an entry in features.networking.wireguard.networks whose
          peers and DNS this tunnel uses. Null for a standalone tunnel that
          defines its own peers.
        '';
      };

      address = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = [ "10.7.0.4/24" ];
        description = "Addresses of this host inside the tunnel.";
      };

      dns = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = ''
          DNS servers to use while the tunnel is up. Null inherits the
          network's dns; set [ ] to configure none.
        '';
      };

      autostart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Bring this tunnel up automatically at boot.";
      };

      privateKeySecret = lib.mkOption {
        type = lib.types.str;
        default = "wg-privateKeyFile";
        example = "wg1-privateKeyFile";
        description = ''
          Name of the sops secret holding this host's private key for the
          tunnel (resolved against the host's sops.defaultSopsFile).
        '';
      };

      peers = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule peerOpts);
        default = [ ];
        description = ''
          Peers for this tunnel, appended to those of the referenced network
          (if any).
        '';
      };
    };
  };

  # Safe lookup: an unknown name yields null so the assertion below reports it
  # instead of nix throwing an attribute-missing trace.
  networkOf = tunnel: if tunnel.network == null then null else cfg.networks.${tunnel.network} or null;

  peersOf =
    tunnel:
    let
      net = networkOf tunnel;
    in
    lib.optionals (net != null) net.peers ++ tunnel.peers;

  dnsOf =
    tunnel:
    let
      net = networkOf tunnel;
    in
    if tunnel.dns != null then
      tunnel.dns
    else if net != null then
      net.dns
    else
      [ ];

  # Every sops secret referenced by any configured tunnel.
  secretNames = lib.unique (
    lib.concatMap (
      tunnel:
      [ tunnel.privateKeySecret ]
      ++ lib.filter (name: name != null) (map (peer: peer.presharedKeySecret) (peersOf tunnel))
    ) (lib.attrValues cfg.tunnels)
  );
in
{
  options.features.networking.wireguard = {
    enable = lib.mkEnableOption "WireGuard client tunnels";

    networks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule networkOpts);
      description = "Catalog of known WireGuard networks that tunnels can reference by name.";
      default = {
        # Personal VPN (bmg-vps). Full tunnel through the VPS, with the
        # VPN-internal resolver so internal names resolve.
        bmg-vps = {
          dns = [ "172.26.0.2" ];
          peers = [
            {
              publicKey = "3xZ1Ug4n8XrjZqlrrrveiIPQq3uyMtxuJXII3vCwyww=";
              endpoint = "35.178.208.8:51820";
              allowedIPs = [ "0.0.0.0/0" ];
              persistentKeepalive = 25;
              presharedKeySecret = "wg-presharedKeyFile";
            }
          ];
        };
      };
    };

    tunnels = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule tunnelOpts);
      default = { };
      example = lib.literalExpression ''
        {
          wg0 = {
            network = "bmg-vps";
            address = [ "10.7.0.4/24" ];
          };
        }
      '';
      description = "WireGuard tunnels to configure on this host, keyed by interface name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: tunnel: [
        {
          assertion = tunnel.network == null || networkOf tunnel != null;
          message = "features.networking.wireguard.tunnels.${name}.network refers to unknown network \"${toString tunnel.network}\"; known networks: ${lib.concatStringsSep ", " (lib.attrNames cfg.networks)}";
        }
        {
          assertion = peersOf tunnel != [ ];
          message = "features.networking.wireguard.tunnels.${name} has no peers: set network, or peers, or both";
        }
        {
          assertion = tunnel.address != [ ];
          message = "features.networking.wireguard.tunnels.${name}.address must not be empty";
        }
      ]) cfg.tunnels
    );

    environment.systemPackages = [ pkgs.wireguard-tools ];

    sops.secrets = lib.genAttrs secretNames (_: {
      owner = "root";
    });

    networking.wg-quick.interfaces = lib.mapAttrs (_: tunnel: {
      inherit (tunnel) autostart address;
      dns = dnsOf tunnel;
      privateKeyFile = config.sops.secrets.${tunnel.privateKeySecret}.path;
      peers = map (peer: {
        inherit (peer)
          publicKey
          allowedIPs
          endpoint
          persistentKeepalive
          ;
        presharedKeyFile =
          if peer.presharedKeySecret == null then
            null
          else
            config.sops.secrets.${peer.presharedKeySecret}.path;
      }) (peersOf tunnel);
    }) cfg.tunnels;
  };
}
