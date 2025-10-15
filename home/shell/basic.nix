{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #Modern Linux tools
    cheat
    delta
    dogdns # DNS client
    #df replacement duf
    duf
    #du replacement dust
    dust
    fd # faster projectile indexing
    # sed for json
    jq
    (ripgrep.override { withPCRE2 = true; })
    # simplified man pages
    tldr
    tree
    psmisc
    shfmt
    shellcheck
    file
    #some network tools
    httpie
    curlie
    xh
    doggo
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
      # The order is important here, because we can override functions in the bashrc
      initExtra =
        ''PROMPT_COMMAND="history -a"''
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
