# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Brian user configuration
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
# - Stored in SOPS encrypted file: users/bmg-secrets.yaml
# - Required for system login
#
# Usage:
#   Automatically imported by profile-common
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.login-password = {
    neededForUsers = true;
    sopsFile = ../../users/bmg-secrets.yaml;
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
    extraGroups =
      [
        "networkmanager"
        "wheel"
        "dialout"
        "plugdev"
      ]
      ++ (lib.optionals (config.features ? development && config.features.development ? docker && config.features.development.docker.enable) [ "docker" ]);
    shell = pkgs.bash;
    uid = 1000;
    hashedPasswordFile = config.sops.secrets.login-password.path;
  };
}
