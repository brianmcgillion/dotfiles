{
  self,
  lib,
  ...
}:
{
  imports = [ self.nixosModules.fail2ban ];

  config = {
    services.openssh = {
      enable = true;
      settings = {
        #PermitRootLogin = lib.mkForce "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        ClientAliveInterval = lib.mkDefault 60;
        LogLevel = "VERBOSE"; # needed for fail2ban
      };
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
