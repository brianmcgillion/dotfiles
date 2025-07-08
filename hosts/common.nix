# SPDX-License-Identifier: Apache-2.0
{
  self,
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.setup.device;
in
{
  imports = lib.flatten [
    (
      with self.nixosModules;
      [
        hardening
        system-packages
        user-bmg
        user-groups
        xdg
        scripts
        my-nebula
      ]
      ++ [
        inputs.nix-index-database.nixosModules.nix-index
        inputs.srvos.nixosModules.mixins-nix-experimental
        inputs.srvos.nixosModules.mixins-trusted-nix-caches
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
      ]
    )
    [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs self;
          };
          #TODO export this from a toplevel login-users module
          users.brian = {
            imports =
              lib.optionals cfg.isClient [ (import ../home/home-client.nix) ]
              ++ lib.optionals cfg.isServer [ (import ../home/home-server.nix) ]
              ++ [ inputs.nix-index-database.hmModules.nix-index ];
          };
        };
      }
    ]
  ];

  options = {
    setup.device = {
      isClient = lib.mkEnableOption "System is a client device";
      isServer = lib.mkEnableOption "System is a server (headless device)";
    };
  };

  config = {
    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        inputs.emacs-overlay.overlays.default
        self.overlays.own-pkgs-overlay
      ];
    };

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];

        # Avoid copying unnecessary stuff over SSH
        builders-use-substitutes = true;
        build-users-group = "nixbld";
        trusted-users = [
          "root"
          "brian"
        ];
        auto-optimise-store = true; # Optimise syslinks
        keep-outputs = true; # Keep outputs of derivations
        keep-derivations = true; # Keep derivations
      };

      # Garbage collection
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };

      # extraOptions = ''
      #   plugin-files = ${pkgs.nix-doc}/lib/libnix_doc_plugin.so
      # '';

      #https://nixos.wiki/wiki/Distributed_build#NixOS
      buildMachines = [
        {
          hostName = "hetzarm";
          system = "aarch64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          mandatoryFeatures = [ ];
          #TODO Fix this
          sshUser = "bmg";
          sshKey = "/home/brian/.ssh/builder-key";
        }
        {
          hostName = "vedenemo-builder";
          system = "x86_64-linux";
          maxJobs = 16;
          speedFactor = 1;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          mandatoryFeatures = [ ];
          #TODO Fix this
          sshUser = "bmg";
          sshKey = "/home/brian/.ssh/builder-key";
        }
      ];

      distributedBuilds = true;
    };

    # only available when dirty
    system.configurationRevision = if (self ? rev) then self.rev else self.dirtyShortRev;

    systemd.services = {
      # Sometimes it fails if a store path is still in use.
      # This should fix intermediate issues.
      nix-gc.serviceConfig = {
        Restart = "on-failure";
      };

      # https://github.com/NixOS/nixpkgs/issues/180175
      NetworkManager-wait-online.enable = false;
    };

    # Common network configuration
    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    networking = {
      useDHCP = false;
      enableIPv6 = false;
      #Open ports in the firewall?
      firewall = {
        enable = true;
      };
      nftables.enable = true;
    };

    ## Local config
    programs = {
      ssh = {
        # use the gcr-ssh-agent
        #startAgent = true;
        extraConfig = ''
          Host hetzarm
               user bmg
               HostName 65.21.20.242
          Host nephele
               Hostname 65.109.25.143
               Port 22
          host ghaf-net
               user ghaf
               IdentityFile ~/.ssh/builder-key
               #hostname 192.168.137.101
               hostname 192.168.10.108 # This is the main IP
               #hostname 192.168.10.45
               #hostname 192.168.10.112 #rodrigo
               #hostname 192.168.10.133 #alien
          host ghaf-host
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.2
               proxyjump ghaf-net
          host ghaf-ui
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.100.3
               proxyjump ghaf-net
          host agx-host
               user ghaf
               IdentityFile ~/.ssh/builder-key
               hostname 192.168.10.149
          host vedenemo-builder
               user bmg
               hostname builder.vedenemo.dev
               IdentityFile ~/.ssh/builder-key
          host caelus
               hostname 95.217.167.39
        '';
        knownHosts = {
          hetzarm-ed25519 = {
            hostNames = [ "65.21.20.242" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILx4zU4gIkTY/1oKEOkf9gTJChdx/jR3lDgZ7p/c7LEK";
          };
          vedenemo-builder = {
            hostNames = [ "builder.vedenemo.dev" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG68NdmOw3mhiBZwDv81dXitePoc1w//p/LpsHHA8QRp";
          };
          nephele = {
            hostNames = [ "65.109.25.143" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwoWKmFa6B9SBci63YG0gaP2kxhXNn1vlMgbky6LjKr";
          };
          caelus = {
            hostNames = [ "95.217.167.39" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHrlodsjLMgGSEM0+NP+0FN7MD6gkySxo7ydKWxP44w";
          };
        };
      };
      # Disable in favor of nix-index-database
      command-not-found = {
        enable = false;
      };

      nix-ld = {
        enable = true;
        #libraries = options.programs.nix-ld.libraries.default;
      };
    };

    # Contents of the user and group files will be replaced on system activation
    # Ref: https://search.nixos.org/options?channel=unstable&show=users.mutableUsers
    users.mutableUsers = false;

    services = {
      # Enable userborn to take care of managing the default users and groups
      userborn.enable = true;
    };

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    boot = {
      # use the bleeding edge kernel
      # should this be changed for the nvidia issues
      kernelPackages = pkgs.linuxPackages_latest;

      binfmt.emulatedSystems = [
        "riscv64-linux"
        "aarch64-linux"
      ];
    };

    # Tie the sops module to the systems ssh keys
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
