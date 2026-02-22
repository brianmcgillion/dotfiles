# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Emacs with Doom configuration
#
# Configures Emacs with Doom Emacs framework and comprehensive development tools.
# Automatically clones Doom Emacs and user configuration on first activation.
#
# Features:
# - Emacs unstable with native compilation
# - Tree-sitter grammars for all languages
# - vterm terminal emulator
# - PDF viewing with pdf-tools
# - Spell checking with aspell
# - Language servers (LSP) for multiple languages:
#   - Bash, TypeScript, YAML, Dockerfile, CMake
#   - Nix (nixd)
#   - GitHub Copilot
# - Formatting tools (prettier, dockfmt)
# - Markdown preview with grip
# - SQLite for org-roam
# - Doom Emacs bin directory added to PATH
#
# Auto-cloned repositories:
# - github.com/doomemacs/doomemacs -> ~/.config/emacs
# - github.com/brianmcgillion/doomd -> ~/.config/doom
#
# Usage:
#   features.development.emacs.enable = true;
#
# Enabled by default in: profile-client
#
# Note: Run 'doom sync' after first install to complete setup
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.development.emacs;
  emacs = (pkgs.emacsPackagesFor pkgs.emacs-git).emacsWithPackages (epkgs: [
    # keep-sorted start
    epkgs.claude-code
    epkgs.djvu
    epkgs.nov
    epkgs.org-pdftools
    epkgs.pdf-tools
    epkgs.tree-sitter-langs
    epkgs.treesit-grammars.with-all-grammars
    epkgs.vterm
    # keep-sorted end
  ]);
in
{
  options.features.development.emacs = {
    enable = lib.mkEnableOption "Emacs with Doom configuration";
  };

  config = lib.mkIf cfg.enable {
    services = {
      emacs = {
        enable = true;
        install = true;
        package = emacs;
        defaultEditor = true;
      };
      languagetool.enable = true;
    };

    environment.sessionVariables = {
      PATH = lib.mkAfter [ "\${XDG_CONFIG_HOME}/emacs/bin" ];
    };

    environment.systemPackages = [
      # keep-sorted start
      (pkgs.aspellWithDicts (ds: [
        # keep-sorted start
        ds.en
        ds.en-computers
        ds.en-science
        # keep-sorted end
      ]))
      emacs
      pkgs.binutils
      pkgs.copilot-language-server
      pkgs.dockerfile-language-server
      pkgs.dockfmt
      pkgs.editorconfig-core-c
      pkgs.github-mcp-server
      pkgs.libxml2
      pkgs.neocmakelsp
      pkgs.nodePackages.bash-language-server
      pkgs.nodePackages.prettier
      pkgs.nodePackages.typescript-language-server
      pkgs.nodePackages.vscode-langservers-extracted
      pkgs.nodePackages.yaml-language-server
      pkgs.nodejs
      pkgs.poppler-utils
      pkgs.python3Packages.grip
      pkgs.sqlite
      pkgs.wordnet
      pkgs.zstd
      # keep-sorted end
    ]
    ++ [ inputs.nixd.packages."${pkgs.stdenv.hostPlatform.system}".nixd ];
  };
}
