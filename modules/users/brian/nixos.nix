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
  features.system.github-token = {
    enable = true;
    sopsFile = ./bmg-secrets.yaml;
    owner = "brian";
  };

  # Remote builders (feature enabled in profile-client); the private key is
  # provisioned from the builder-key sops secret so fresh installs build
  # remotely without hand-copying it.
  features.system.remote-builders = {
    sshUser = "bmg";
    sshKeySopsFile = ./bmg-secrets.yaml;
  };

  # Personal SSH host aliases live in home-manager
  # (home/security/ssh-config.nix), not in /etc/ssh/ssh_config.

  sops.secrets.login-password = {
    neededForUsers = true;
    sopsFile = ./bmg-secrets.yaml;
  };

  users.users.brian = {
    isNormalUser = true;
    home = "/home/brian";
    description = "Brian";
    openssh.authorizedKeys.keys =
      # YubiKey SSH keys (all of them — same set root accepts)
      self.lib.keys.brian.yubikeys ++ [
        # Builder key for automated deployments. NOTE: unrestricted here, and
        # brian has passwordless sudo — so this key is root-equivalent on every
        # host regardless of the restrictions applied to root's own keys.
        self.lib.keys.brian.builder
      ];
    # The docker/ai feature modules are only imported on some profiles, so
    # guard with `or false` (handles missing attrs at any depth).
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "plugdev"
    ]
    ++ (lib.optionals (config.features.development.docker.enable or false) [ "docker" ])
    ++ (lib.optionals (config.features.ai.enable or false) [ "ollama" ]);
    shell = pkgs.bash;
    uid = 1000;
    hashedPasswordFile = config.sops.secrets.login-password.path;
  };

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Move pre-existing conflicting files aside instead of aborting the
    # whole activation (tool-managed files get recreated at runtime).
    backupFileExtension = "hm-bak";
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
