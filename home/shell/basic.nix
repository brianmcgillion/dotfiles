{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #Modern Linux tools
    cheat
    delta # TODO configure in .gitconfig https://dandavison.github.io/delta/configuration.html   (DELTA_PAGER)
    dog
    fd # faster projectile indexing
    (ripgrep.override { withPCRE2 = true; })
    tree
    psmisc
    shfmt
    shellcheck
    file
  ];

  programs = {
    pandoc.enable = true;

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
