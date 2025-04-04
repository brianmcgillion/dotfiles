{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.security.ssh;
in {
  config = mkIf cfg {
    programs.ssh = {
      enable = true;
      
      # Keep existing SSH configuration
      forwardAgent = true;
      serverAliveInterval = 60;
      
      # Any additional SSH configuration...
      
      # If you have custom SSH matching rules, keep them:
      # matchBlocks = {
      #   "example-host" = {
      #     hostname = "example.com";
      #     user = "username";
      #     port = 2222;
      #   };
      # };
      
      # If you have extra SSH options, keep them:
      # extraConfig = ''
      #   AddKeysToAgent yes
      #   IdentitiesOnly yes
      # '';
    };
    
    # Enable ssh-agent service
    services.ssh-agent.enable = true;
  };
}
