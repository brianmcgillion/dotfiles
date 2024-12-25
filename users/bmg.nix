# SPDX-License-Identifier: Apache-2.0
{ config, ... }:
{

  sops.secrets.login-password = {
    neededForUsers = true;
    sopsFile = ./bmg-secrets.yaml;
  };

  users.users = {
    brian = {
      isNormalUser = true;
      home = "/home/brian";
      description = "Brian";
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEJ9ewKwo5FLj6zE30KnTn8+nw7aKdei9SeTwaAeRdJDAAAABHNzaDo="
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA/pwHnzGNM+ZU4lANGROTRe2ZHbes7cnZn72Oeun/MCAAAABHNzaDo="
      ];
      extraGroups = [
        "networkmanager"
        "wheel"
        "dialout"
        "plugdev"
      ];
      shell = "/run/current-system/sw/bin/bash";
      uid = 1000;
      hashedPasswordFile = config.sops.secrets.login-password.path;
    };
  };

  # sops.secrets.netrc-file = {
  #   owner = "brian";
  #   mode = "0600";
  #   sopsFile = ./bmg-secrets.yaml;
  #   path = "/home/brian/.netrc";
  # };

  # sops.secrets.builder-key = {
  #   owner = "brian";
  #   mode = "0600";
  #   sopsFile = ./bmg-secrets.yaml;
  #   path = "/home/brian/.ssh/builder-key.test";
  # };
}
