# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Community cheatsheets, pinned rather than kept as a live git clone in $HOME.
  # cheat's first-run prompt clones this repo and then never updates it again:
  # ours sat on a 2022-08 commit until seven sheets with malformed frontmatter
  # (`tags [ x ]` rather than `tags: [ x ]`) made `cheat -l` fail outright --
  # cheat aborts the whole listing on the first unparseable sheet. A pinned
  # store path cannot drift, and is immutable, which matches the `readonly`
  # cheatpath below. Upstream is dormant and this is its tip, so refreshing the
  # sheets is a reviewed rev+hash bump.
  cheatsheets = pkgs.fetchFromGitHub {
    owner = "cheat";
    repo = "cheatsheets";
    rev = "36bdb99dcfadde210503d8c2dcf94b34ee950e1d";
    hash = "sha256-Afv0rPlYTCsyWvYx8UObKs6Me8IOH5Cv5u4fO38J8ns=";
  };

  personalDir = "${config.xdg.configHome}/cheat/cheatsheets/personal";
in
{
  home.packages = [ pkgs.cheat ];

  # Generated as YAML rather than written out as text, so that quoting and list
  # syntax cannot drift into the same frontmatter breakage described above.
  xdg.configFile."cheat/conf.yml".source = (pkgs.formats.yaml { }).generate "cheat-conf.yml" {
    editor = "emacs";

    # Colouring is bat's job here, not cheat's. The two cannot both do it:
    # with `colorize = true` bat syntax-highlights the escape codes chroma
    # emits, chopping `ESC[38;5;61m` into fragments that render as visible
    # text. So cheat emits plain output and bat colours it, picking up
    # `--theme = Dracula` from programs.bat in basic.nix -- one source of truth
    # for theming, and true colour rather than chroma's 256. cheat's
    # `style`/`formatter` settings only apply when `colorize` is true, so they
    # are omitted rather than left behind as dead config.
    #
    # `-l bash` is required because bat cannot infer a syntax from stdin. It
    # means every sheet is highlighted as shell, which suits nearly all of
    # them, at the cost of ignoring any per-sheet `syntax:` frontmatter.
    colorize = false;
    pager = "bat -l bash --style=plain";

    # Cheatpaths are scoped: the more "local" path wins, so personal sheets
    # override dotfiles ones, which in turn override community ones. Sheets
    # tracked in this repo sit in the middle, marked readonly so that
    # `cheat -e <sheet>` copy-on-writes them into the personal path instead of
    # failing against a store path.
    cheatpaths = [
      {
        name = "community";
        path = "${cheatsheets}";
        tags = [ "community" ];
        readonly = true;
      }
      {
        name = "dotfiles";
        path = "${./cheatsheets}";
        tags = [ "dotfiles" ];
        readonly = true;
      }
      {
        name = "personal";
        path = personalDir;
        tags = [ "personal" ];
        readonly = false;
      }
    ];
  };

  # `cheat -e` writes new sheets here, so this has to be a real writable
  # directory rather than a symlink into the store.
  home.activation.cheatPersonalDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg personalDir}
  '';
}
