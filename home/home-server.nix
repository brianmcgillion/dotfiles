{ ... }:
{
  imports = [
    ./home.nix
    ./home-config.nix
  ];
  
  modules.home = {
    shell = {
      enable = true;
      basic = true;
      fzf = true;
      git = true;
      # No need for GUI terminals on server
      kitty = false;
      terminator = false;
      ghostty = false;
      tmux = true;
    };
    
    # Minimal server config - no GUI apps
    apps.enable = false;
    development = {
      enable = true;
      base = true;
      graphical = false;
      embedded = false;
    };
    
    browsers = {
      enable = false;  # Disable all browsers on server
    };
    
    security = {
      enable = true;
      ssh = true;
      gpg = false;  # Disable GPG by default
    };
  };
}
