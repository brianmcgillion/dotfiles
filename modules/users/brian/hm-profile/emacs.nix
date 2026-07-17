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
    # Clone Doom Emacs and user config before emacs.service starts.
    # network-online.target does not exist in the systemd *user* manager, so
    # the script retries instead of ordering on it — on first login of a
    # fresh install the network may not be up yet.
    systemd.user.services.install-doom-emacs = {
      Unit = {
        Description = "Clone Doom Emacs and user configuration";
        Before = [ "emacs.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "install-doom-emacs" ''
          clone_with_retry() {
            url="$1"
            dest="$2"
            [ -d "$dest" ] && return 0
            for delay in 5 15 30 60; do
              ${pkgs.git}/bin/git clone "$url" "$dest" && return 0
              rm -rf "$dest"
              echo "clone of $url failed, retrying in $delay s" >&2
              sleep "$delay"
            done
            ${pkgs.git}/bin/git clone "$url" "$dest"
          }
          clone_with_retry https://github.com/doomemacs/doomemacs.git "$HOME/.config/emacs"
          clone_with_retry https://github.com/brianmcgillion/doomd.git "$HOME/.config/doom"
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
