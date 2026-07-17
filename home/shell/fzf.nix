# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = [ pkgs.fzf-git-sh ];

  programs = {
    fzf = {
      enable = true;
      defaultCommand = "fd --hidden --follow --exclude .git";
      defaultOptions = [ "--layout reverse" ];
      colors = {
        #
        fg = "-1";
        bg = "-1";
        hl = "#5fff87";
        "fg+" = "-1";
        "bg+" = "-1";
        "hl+" = "#ffaf5f";
        #
        info = "#af87ff";
        prompt = "#5fff87";
        pointer = "#ff87d7";
        marker = "#ff87d7";
        spinner = "#ff87d7";
      };

      changeDirWidget = {
        command = "fd --type d --hidden --follow --exclude .git"; # ALT_C command
        options = [ "--preview 'eza --tree --color=always {} | head -200'" ];
      };
      fileWidget = {
        command = "fd --hidden --follow --exclude .git"; # CTRL_T command
        options = [ "--preview 'bat --color=always -n --line-range :500 {}'" ];
      };
    };
  };
}
