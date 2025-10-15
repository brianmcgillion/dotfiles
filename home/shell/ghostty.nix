{ pkgs, ... }:
{
  programs = {
    ghostty = {
      enable = true;
      enableBashIntegration = true;
      package = pkgs.ghostty;
      settings = {
        font-size = 10;
        shell-integration-features = "no-cursor,sudo,no-title";
        theme = "Dracula";
        #font-family = "\"FiraCode Nerd Font\"";
        #fullscreen = true;
        #window-save-state = "always";
        #window-decoration = false;
        # keybind = [
        #   "ctrl+alt+x=toggle_split_zoom"
        #   "ctrl+alt+q=close_window"
        # ];
      };
    };
  };
}
