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

      #--multi --inline-info --preview='[[ \\$(file --mine {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) 2>/dev/null | head -300' --preview-window='right:hidden:wrap' --bind='f3:execute(bat --style=numbers {} || less -f {}),f2:toggle-preview,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-a:select-all+accept,ctrl-y:execute-silent(echo {+} | pbcopy)'"
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git"; # ALT_C command
      changeDirWidgetOptions = [ "--preview 'eza --tree --color=always {} | head -200'" ];
      fileWidgetCommand = "fd --hidden --follow --exclude .git"; # CTRL_T command
      fileWidgetOptions = [ "--preview 'bat --color=always -n --line-range :500 {}'" ];
    };
  };
}
