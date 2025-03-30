{ pkgs, lib, ... }:
{
  home.file.".ssh/allowed_signers".text = "${builtins.readFile ../../keys/ssh-keys.txt}";

  programs = {
    git = {
      package = pkgs.gitAndTools.gitFull;
      enable = true;
      userName = "Brian McGillion";
      userEmail = "bmg.avoin@gmail.com";

      aliases = {
        checkout-pr = "!pr() { git fetch origin pull/$1/head:pr-$1; git checkout pr-$1; }; pr";
        pick-pr = "!am() { git fetch origin pull/$1/head:pr-$1; git cherry-pick HEAD..pr-$1; }; am";
        reset-pr = "reset --hard FETCH_HEAD";
      };
      delta.enable = true; # see diff in a new light
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
      ignores = [
        "*~"
        "*.swp"
        ".worktrees/"
      ];
      signing = {
        format = "ssh";
        signByDefault = true;
      };
      extraConfig = {
        #core.editor = "emacs";
        color.ui = "auto";
        #credential.helper = "store --file ~/.git-credentials";
        format.signoff = true;
        commit.gpgsign = true;
        tag.gpgSign = true;
        gpg.format = lib.mkDefault "ssh";
        user.signingkey = "~/.ssh/id_ed25519_sk.pub";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        init.defaultBranch = "main";
        #protocol.keybase.allow = "always";
        pull.rebase = "true";
        push.default = "current";
        github.user = "brianmcgillion";
        gitlab.user = "bmg";
      };
    };

    gh = {
      enable = true;
      extensions = with pkgs; [
        gh-poi
        gh-eco
        gh-dash
        gh-markdown-preview
        gh-copilot
        gh-f
      ];
    };

    git-worktree-switcher = {
      enable = true;
      enableBashIntegration = true;
      package = pkgs.git-worktree-switcher;
    };
  };
}
