# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  pkgs,
  lib,
  self,
  ...
}:
let
  signingIdentity = "bmg.avoin@gmail.com";
in
{
  # Trust every YubiKey to sign, from the same list that authorizes them for
  # login (../keys).
  #
  # The ALLOWED SIGNERS format requires a principal (identity) as the first
  # token of every line; bare public keys make `git verify-commit` fail with
  # "No principal matched".
  home.file.".ssh/allowed_signers".text = lib.concatMapStrings (
    key: "${signingIdentity} ${key}\n"
  ) self.lib.keys.brian.yubikeys;

  programs = {
    git = {
      #package = pkgs.gitAndTools.gitFull;
      enable = true;

      settings = {
        user = {
          name = "Brian McGillion";
          email = "bmg.avoin@gmail.com";
        };

        alias = {
          checkout-pr = "!pr() { git fetch origin pull/$1/head:pr-$1; git checkout pr-$1; }; pr";
          pick-pr = "!am() { git fetch origin pull/$1/head:pr-$1; git cherry-pick HEAD..pr-$1; }; am";
          reset-pr = "reset --hard FETCH_HEAD";
          update-PR = "!upr() { git fetch origin pull/$1/head && git reset --hard FETCH_HEAD; }; upr";
          qc = "commit --no-verify";
        };

        #core.editor = "emacs";
        color.ui = "auto";
        checkout.defaultRemote = "origin";
        #credential.helper = "store --file ~/.git-credentials";
        format.signoff = true;
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        init.defaultBranch = "main";
        #protocol.keybase.allow = "always";
        pull.rebase = true;
        push.default = "current";
        github.user = "brianmcgillion";
        gitlab.user = "bmg";

      };

      ignores = [
        "*~"
        "*.swp"
        ".worktrees/"
      ];

      # signing.* generates commit.gpgsign, tag.gpgSign, gpg.format and
      # user.signingkey — do not restate them under settings.
      signing = {
        format = "ssh";
        signByDefault = true;
        key = "~/.ssh/id_ed25519_sk.pub";
      };
    };

    delta = {
      enable = true; # see diff in a new light
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
    };

    gh = {
      enable = true;
      extensions = [
        # keep-sorted start
        pkgs.gh-dash
        pkgs.gh-eco
        pkgs.gh-f
        pkgs.gh-markdown-preview
        pkgs.gh-poi
        # keep-sorted end
      ];
    };

    git-worktree-switcher = {
      enable = true;
      enableBashIntegration = true;
      package = pkgs.git-worktree-switcher;
    };
  };
}
