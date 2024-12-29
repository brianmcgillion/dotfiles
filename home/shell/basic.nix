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
      nix-direnv.enable = true;
    };

    eza.enable = true;

    bash = {
      enable = true;
      initExtra = builtins.readFile ./bashrc;
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
