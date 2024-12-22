# SPDX-License-Identifier: Apache-2.0
_: {
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
      #Set an initial dummy "Password" for the first boot
      # sudo -i ; passwd <username>
      hashedPassword = "$6$F0XwJUE0WhvpDo89$RTU5XkHAa50JcxzGClbzmIZjAP80v/TrqGq.WbkxGbXaotf9.er8mbMO/w2lIvwmCHNeCLJznG7TGhziPDtyf/";
    };
  };
}
