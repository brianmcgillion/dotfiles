# SPDX-License-Identifier: MIT
{ self, ... }:
{
  home = {
    #TODO ask Brian about config
    username = "brian"; # config.users.users.brian.name;
    homeDirectory = "/home/brian"; # config.users.users.brian.home;
    stateVersion = "23.05";
  };

  ### A tidy $HOME is a tidy mind
  xdg.enable = true;

  programs = {
    home-manager.enable = true;
  };
}
