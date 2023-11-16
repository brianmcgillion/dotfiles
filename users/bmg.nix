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
      extraGroups = ["networkmanager" "wheel" "dialout" "plugdev"];
      hashedPassword = "$y$j9T$vEb9JvWNSs9/1cHz8h4Mt1$40SOms0moILeEUaD7dXje.husHsyZVCLtWhRMPFMcE7";
    };
  };
}
