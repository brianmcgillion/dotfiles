# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Brian user NixOS configuration
#
# Configures the primary user account with:
# - SOPS-encrypted password
# - YubiKey SSH authentication
# - Administrative privileges (wheel group)
# - Hardware access (dialout, plugdev groups)
# - NetworkManager access
#
# SSH keys:
# - Two YubiKey-based SSH keys (sk-ssh-ed25519)
# - Hardware-backed authentication
#
# Groups:
# - wheel: sudo/administrative access
# - networkmanager: network configuration
# - dialout: serial port access (Arduino, embedded dev)
# - plugdev: USB device access (hardware development)
# - docker: container management (when Docker is enabled)
#
# Shell: Bash (from package set)
# UID: 1000 (standard first user)
#
# Password management:
# - Stored in SOPS encrypted file: modules/users/brian/bmg-secrets.yaml
# - Required for system login
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # Nix settings
  nix.settings.trusted-users = [ "brian" ];

  # GitHub token for Nix flake operations (avoiding rate limits)
  features.system.nix-settings = {
    enable = true;
    githubToken = {
      enable = true;
      sopsFile = ./bmg-secrets.yaml;
    };
  };

  # Remote build settings (defined in common.nix)
  common.remoteBuild = {
    sshUser = "bmg";
    sshKey = "/home/brian/.ssh/builder-key";
  };

  # SSH client configuration (system-wide, but user-specific settings)
  programs.ssh.extraConfig = ''
    Host hetzarm
         user bmg
         HostName 65.21.20.242
    Host nubes
         Hostname 65.108.111.248
         Port 22
    host ghaf-net
         user ghaf
         IdentityFile ~/.ssh/builder-key
         #hostname 192.168.10.108 #x1-carbon
         hostname 192.168.10.229 #darter-pro
         #hostname 192.168.10.34 #usb-ethernet
    host ghaf-usb
         user ghaf
         IdentityFile ~/.ssh/builder-key
         hostname 192.168.10.34 #usb-ethernet
    host ghaf-host
         user ghaf
         IdentityFile ~/.ssh/builder-key
         hostname 192.168.100.2
         proxyjump ghaf-net
    host ghaf-host-usb
         user ghaf
         IdentityFile ~/.ssh/builder-key
         hostname 192.168.100.2
         proxyjump ghaf-usb
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
    host uae-lab-node1
         user bmg
         hostname 10.161.5.196
  '';

  sops.secrets.login-password = {
    neededForUsers = true;
    sopsFile = ./bmg-secrets.yaml;
  };

  users.users.brian = {
    isNormalUser = true;
    home = "/home/brian";
    description = "Brian";
    openssh.authorizedKeys.keys = [
      # YubiKey SSH keys
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEJ9ewKwo5FLj6zE30KnTn8+nw7aKdei9SeTwaAeRdJDAAAABHNzaDo="
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA/pwHnzGNM+ZU4lANGROTRe2ZHbes7cnZn72Oeun/MCAAAABHNzaDo="
      # Builder key for automated deployments
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu6O3swRVWAjP7J8iYGT6st7NAa+o/XaemokmtKdpGa builder key"
    ];
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "plugdev"
    ]
    ++ (lib.optionals (
      config.features ? development
      && config.features.development ? docker
      && config.features.development.docker.enable
    ) [ "docker" ]);
    shell = pkgs.bash;
    uid = 1000;
    hashedPasswordFile = config.sops.secrets.login-password.path;
  };

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users.brian = {
      imports = [
        self.homeModules."home-profile-${config.common.profile.target}"
        inputs.nix-index-database.homeModules.nix-index
        # Brian's user-specific configuration (git identity, Doom config, etc.)
        self.homeModules.user-profile-brian
      ];

      # Enable Emacs config only on client systems
      userProfile.enableEmacs = config.common.profile.target == "client";
    };
  };
}
