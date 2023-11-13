{config, ...}: {
  imports = [
    ./shell
    ./apps
    ./browsers
    ./development
  ];
  # ++ [(import ./apps)]
  # ++ [(import ./browsers)]
  # ++ [(import ./development)];

  #TODO Remove this in tidy phase
  # home = {
  #   username = "${user}";
  #   homeDirectory = "/home/${user}";

  #   stateVersion = "23.05";
  # };

  home = {
    #TODO ask Brian about config
    username = "brian"; #config.users.users.brian.name;
    homeDirectory = "/home/brian"; #config.users.users.brian.home;
    stateVersion = "23.05";
  };

  ### A tidy $HOME is a tidy mind
  xdg.enable = true;

  programs = {
    home-manager.enable = true;
    bash.enable = true;
  };
}
