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
  emacs =
    with pkgs;
    ((emacsPackagesFor emacs-git).emacsWithPackages (
      epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
        tree-sitter-langs
        vterm
        pdf-tools
        org-pdftools
      ]
    ));
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

    environment.systemPackages =
      with pkgs;
      [
        # keep-sorted start
        (aspellWithDicts (
          ds: with ds; [
            # keep-sorted start
            en
            en-computers
            en-science
            # keep-sorted end
          ]
        ))
        binutils
        copilot-language-server
        dockerfile-language-server
        dockfmt
        editorconfig-core-c
        emacs
        github-mcp-server
        inputs.mcp-nixos.packages."${pkgs.stdenv.hostPlatform.system}".default
        libxml2
        neocmakelsp
        nodePackages.bash-language-server
        nodePackages.prettier
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
        nodePackages.yaml-language-server
        nodejs
        python3Packages.grip
        sqlite
        wordnet
        zstd
        # keep-sorted end
      ]
      ++ [ inputs.nixd.packages."${pkgs.stdenv.hostPlatform.system}".nixd ];
  };
}
