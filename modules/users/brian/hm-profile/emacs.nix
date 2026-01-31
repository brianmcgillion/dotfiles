# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Doom Emacs user configuration
#
# Installs user-specific Doom Emacs configuration.
# Automatically clones Doom Emacs and user configuration on first activation.
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
    # Doom Emacs installation and user config
    # $DRY_RUN_CMD is provided by home-manager for dry-run support
    # See: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-activation
    home.activation.installDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/doomemacs/doomemacs.git "$XDG_CONFIG_HOME/emacs"
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/brianmcgillion/doomd.git "$XDG_CONFIG_HOME/doom"
      fi
    '';

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
