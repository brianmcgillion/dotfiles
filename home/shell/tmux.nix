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
      plugins = [
        # keep-sorted start
        pkgs.tmuxPlugins.better-mouse-mode
        pkgs.tmuxPlugins.dracula
        pkgs.tmuxPlugins.sensible
        pkgs.tmuxPlugins.tmux-fzf
        {
          plugin = pkgs.tmuxPlugins.tmux-which-key;
          extraConfig = "set -g @tmux-which-key-xdg-enable 1";
        }
        #pkgs.tmuxPlugins.sysstat
        #pkgs.tmuxPlugins.tmux-powerline
        #pkgs.tmuxPlugins.tmux-thumbs
        # keep-sorted end
      ];
      terminal = "tmux-256color";
    };
  };
}
