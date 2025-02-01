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
      ];
    };
  };
}
