{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.fail2ban;
in {
  options.modules.fail2ban = {
    enable = mkEnableOption "Fail2ban intrusion prevention";
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 3; # Observe 3 violations before banning an IP
      ignoreIP = [
        # Anything constant
      ];
      bantime = "24h"; # Set bantime to one day
      bantime-increment = {
        enable = true; # Enable increment of bantime after each violation
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h"; # Do not ban for more than 1 week
        overalljails = true; # Calculate the bantime based on all the violations
      };
    };
  };
}
