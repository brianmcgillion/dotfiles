{ ... }:
{
  imports = [
    ./home.nix
    ./home-config.nix
  ];
  
  modules.home = {
    # Enable all major module categories
    shell = {
      enable = true;
      basic = true;
      fzf = true;
      git = true;
      kitty = true;
      terminator = true;
      ghostty = true;
      tmux = true;
    };
    
    apps = {
      enable = true;
      chat = true;
      documents = true;
    };
    
    development = {
      enable = true;
      base = true;
      graphical = true;
      embedded = true;
    };
    
    browsers = true;
    security = true;
  };
}
