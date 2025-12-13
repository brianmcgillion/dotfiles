# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    (ripgrep.override { withPCRE2 = true; })
    cheat
    curlie
    delta
    dogdns # DNS client
    doggo
    duf # df replacement
    dust # du replacement
    fd # faster projectile indexing
    file
    httpie
    jq # sed for json
    psmisc
    shellcheck
    shfmt
    tldr # simplified man pages
    tree
    xh
    # keep-sorted end
  ];

  programs = {
    bat = {
      enable = true; # BAT_PAGER
      config = {
        theme = "Dracula";
      };
    };

    htop.enable = true; # TODO enable the correct layout

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
      historySize = 10000;
      historyFileSize = 20000;
      historyControl = [
        "ignoreboth"
        "erasedups"
      ];
      shellOptions = [
        "histappend"
      ];
      # The order is important here, because we can override functions in the bashrc
      initExtra = ''
        # Bash history synchronization across terminals
        # - history -a: Append new commands to history file
        # - history -n: Read new history entries from file (commands from other terminals)
        # This shares history across terminals with less overhead than -c; -r
        # Note: Only new entries since last read are loaded, not full re-read
        PROMPT_COMMAND="history -a; history -n"

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
