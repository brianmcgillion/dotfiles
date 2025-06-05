# SPDX-License-Identifier: MIT
_: {
  home = {
    stateVersion = "23.05";
  };

  ### A tidy $HOME is a tidy mind
  xdg.enable = true;

  programs = {
    home-manager.enable = true;
  };

  systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-auth.sock";
}
