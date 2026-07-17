# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Distributed builds on external builder machines
#
# Configures nix.buildMachines for the work builders (hetzarm aarch64,
# vedenemo x86_64) including their host aliases and pinned host keys, and
# optionally provisions the SSH private key from sops so fresh installs
# build remotely without hand-copying a key.
#
# The nix daemon (root) performs the SSH connections; the key is also the
# identity used by deploy-rs and the personal ssh aliases, so it is owned by
# sshKeyOwner and left at its /run/secrets path (see sshKey's description for
# why it must not live under ~/.ssh).
#
# Usage:
#   features.system.remote-builders = {
#     enable = true;
#     sshUser = "bmg";
#     sshKeySopsFile = ./secrets.yaml;  # must contain a builder-key entry
#   };
#
# Enabled by default in: profile-client (servers build locally)
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.system.remote-builders;

  mkBuilder = hostName: system: {
    inherit hostName system;
    maxJobs = 16;
    speedFactor = 1;
    supportedFeatures = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
    inherit (cfg) sshUser sshKey;
  };
in
{
  options.features.system.remote-builders = {
    enable = lib.mkEnableOption "distributed builds on external builder machines";

    sshUser = lib.mkOption {
      type = lib.types.str;
      example = "builder";
      description = ''
        SSH username for connecting to the remote Nix build machines.
        This user must have permission to run Nix builds on the remote system.
      '';
    };

    sshKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "builder-key";
      description = "Name of the sops secret holding the private key.";
    };

    sshKey = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/${cfg.sshKeySecret}";
      defaultText = lib.literalExpression ''"/run/secrets/''${sshKeySecret}"'';
      description = ''
        Path to the SSH private key used to authenticate to the builders.
        The corresponding public key must be in the authorized_keys of the
        remote builder user. Also consumed by the personal ssh aliases
        (home/security/ssh-config.nix) and deploy-rs, which use the same key.

        Deliberately NOT under a home directory: sops-install-secrets creates
        missing parent directories as root, so pointing a secret at
        ~/.ssh/<key> on a fresh install would leave ~/.ssh root-owned before
        home-manager gets to write ~/.ssh/config into it. /run/secrets.d is
        world-traversable (0751) and the secret itself is owned by
        sshKeyOwner, so both root (nix daemon) and that user can read it.
      '';
    };

    sshKeyOwner = lib.mkOption {
      type = lib.types.str;
      default = "brian";
      description = ''
        Owner of the provisioned key. The nix daemon reads it as root
        regardless; this is the user who may use it interactively
        (deploy-rs, ssh aliases).
      '';
    };

    sshKeySopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        When set, provision the private key from the sshKeySecret entry in
        this sops file. When null the key must be placed at sshKey manually.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        nix = {
          distributedBuilds = true;
          # https://nixos.wiki/wiki/Distributed_build#NixOS
          buildMachines = [
            (mkBuilder "hetzarm" "aarch64-linux")
            (mkBuilder "vedenemo-builder" "x86_64-linux")
          ];
        };

        programs.ssh = {
          # Name resolution for the builder aliases used above; the nix
          # daemon connects as root, so these must be system-wide (not
          # home-manager) config.
          extraConfig = ''
            Host hetzarm
                 HostName 65.21.20.242
            Host vedenemo-builder
                 HostName builder.vedenemo.dev
          '';

          knownHosts = {
            hetzarm = {
              hostNames = [ "65.21.20.242" ];
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
            };
            vedenemo-builder = {
              hostNames = [ "builder.vedenemo.dev" ];
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
            };
          };
        };
      }

      (lib.mkIf (cfg.sshKeySopsFile != null) {
        # No `path` override: the secret stays at the sops default
        # (/run/secrets/<name>), which is what sshKey points at.
        sops.secrets.${cfg.sshKeySecret} = {
          sopsFile = cfg.sshKeySopsFile;
          owner = cfg.sshKeyOwner;
          mode = "0400";
        };
      })
    ]
  );
}
