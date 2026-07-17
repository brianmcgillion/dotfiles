# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home = {
    packages = [
      # keep-sorted start
      pkgs.cheat
      pkgs.curlie
      pkgs.delta
      pkgs.doggo # dns related like dogdns
      pkgs.duf # df replacement
      pkgs.dust # du replacement
      pkgs.fd # faster projectile indexing
      pkgs.httpie
      pkgs.jq # sed for json
      pkgs.psmisc
      pkgs.ripgrep # PCRE2 support is the nixpkgs default
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.tldr # simplified man pages
      pkgs.xh
      # keep-sorted end
    ];
  };

  # Ensure bash state directory exists for history (HISTFILE is set to
  # $XDG_STATE_HOME/bash/history in modules/features/system/xdg.nix).
  # xdg.stateFile anchors under the real stateHome automatically.
  xdg.stateFile."bash/.keep".text = "";

  programs = {
    bat = {
      enable = true; # BAT_PAGER
      config = {
        theme = "Dracula";
      };
    };

    starship.enable = true;

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    eza = {
      enable = true;
      colors = "always";
      #icons = "always";
    };

    bash = {
      enable = true;
      historySize = 100000;
      historyFileSize = 200000;
      historyControl = [
        "ignoredups"
        "ignorespace"
      ];
      shellOptions = [
        "histappend"
      ];
      # The order is important here, because we can override functions in the bashrc
      initExtra = ''
        # Disable history for GitHub Copilot CLI sessions
        # Copilot sets GITHUB_COPILOT_CLI=1 when running commands
        if [[ -n "$GITHUB_COPILOT_CLI" ]]; then
          unset HISTFILE
        else
          # Bash history synchronization across terminals (only for interactive sessions)
          # - history -a: Append new commands to history file
          # - history -n: Read new history entries from file (commands from other terminals)
          # This shares history across terminals with less overhead than -c; -r
          # Note: Only new entries since last read are loaded, not full re-read
          PROMPT_COMMAND="history -a; history -n"
        fi

        # Add timestamps to history
        HISTTIMEFORMAT='%F %T '
      ''
      + "\n\n[ -f ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh ] && source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh\n\n"
      + builtins.readFile ./bashrc;
    };

    # improved cd
    zoxide = {
      enable = true;
    };

    nix-index.enable = true;
  };

  home.shellAliases = {
    cat = "bat";
  };
}
