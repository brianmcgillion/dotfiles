# SPDX-License-Identifier: Apache-2.
{ pkgs, config, ... }:
{
  programs = {
    kitty = {
      enable = true;
      font = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
      shellIntegration.enableBashIntegration = true;
      themeFile = "Dracula";
      settings = {
        enable_audio_bell = false;
        enabled_layouts = "grid,stack,horizontal,tall";
        startup_session = "${config.xdg.configHome}/kitty/startup_session.conf";
        wayland_titlebar_color = "black";
        copy_on_select = "yes";
      };
      keybindings = {
        "ctrl+alt+g" = "goto_layout grid";
        "ctrl+alt+x" = "goto_layout stack";
      };
      extraConfig = "";
    };
  };

  # Can see the options for changing layout and session here:
  # https://sw.kovidgoyal.net/kitty/overview/#startup-sessions
  xdg.configFile."kitty/startup_session.conf" = {
    text = ''
      os_window_state maximized
      enabled_layouts grid,stack
      launch
      launch
      launch
      launch
      layout grid
    '';
  };
}
