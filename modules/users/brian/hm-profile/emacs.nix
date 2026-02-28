# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Doom Emacs user configuration
#
# Installs user-specific Doom Emacs configuration.
# Automatically clones Doom Emacs and user configuration via systemd user service.
#
# Repositories:
# - github.com/doomemacs/doomemacs -> ~/.config/emacs
# - github.com/brianmcgillion/doomd -> ~/.config/doom (Brian's config)
#
# org-protocol:
# - Desktop file registers emacsclient as handler for org-protocol:// URLs
# - Use with browser bookmarklet or extension to capture web pages to org-mode
#
# Note: Run 'doom sync' after first install to complete setup
# Only enabled when userProfile.enableEmacs is true
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.userProfile.enableEmacs {
    # Clone Doom Emacs and user config before emacs.service starts
    systemd.user.services.install-doom-emacs = {
      Unit = {
        Description = "Clone Doom Emacs and user configuration";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        Before = [ "emacs.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "install-doom-emacs" ''
          if [ ! -d "$HOME/.config/emacs" ]; then
            ${pkgs.git}/bin/git clone https://github.com/doomemacs/doomemacs.git "$HOME/.config/emacs"
          fi
          if [ ! -d "$HOME/.config/doom" ]; then
            ${pkgs.git}/bin/git clone https://github.com/brianmcgillion/doomd.git "$HOME/.config/doom"
          fi
        '';
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # org-protocol desktop handler for browser integration
    # Allows capturing web pages to org-mode via org-protocol:// URLs
    xdg.desktopEntries.org-protocol = {
      name = "Org Protocol";
      comment = "Handle org-protocol:// URLs for Emacs capture";
      exec = "emacsclient -- %u";
      icon = "emacs";
      type = "Application";
      mimeType = [ "x-scheme-handler/org-protocol" ];
      categories = [
        "Development"
        "TextEditor"
      ];
      noDisplay = true;
    };

    # Register org-protocol handler with the desktop environment
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/org-protocol" = [ "org-protocol.desktop" ];
      };
    };
  };
}
