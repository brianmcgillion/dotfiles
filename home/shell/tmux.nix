# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  programs = {
    tmux = {
      enable = true;
      clock24 = true;
      mouse = true;
      newSession = true;
      plugins = with pkgs; [
        tmuxPlugins.dracula
        tmuxPlugins.tmux-fzf
        tmuxPlugins.sensible
        tmuxPlugins.tmux-which-key
        #tmuxPlugins.tmux-thumbs
        #tmuxPlugins.sysstat
        tmuxPlugins.better-mouse-mode
        #tmuxPlugins.tmux-powerline
      ];
      terminal = "tmux-256color";
    };
  };
}
