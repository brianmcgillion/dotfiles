{pkgs, ...}: {
  # TODO add conf file and settings and secrets store
  #
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Brian McGillion";
    userEmail = "bmg.avoin@gmail.com";
    delta.enable = true; # see diff in a new light
    delta.options = {
      line-numbers = true;
      side-by-side = true;
      syntax-theme = "Dracula";
    };
    ignores = ["*~" "*.swp"];
    extraConfig = {
      core.editor = "emacs";
      color.ui = "auto";
      #credential.helper = "store --file ~/.git-credentials";
      format.signoff = true;
      init.defaultBranch = "main";
      #protocol.keybase.allow = "always";
      pull.rebase = "true";
      push.default = "current";
      github.user = "brianmcgillion";
      gitlab.user = "bmg";
    };
  };

  programs.gh = {
    enable = true;
  };
}
