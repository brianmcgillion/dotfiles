{
  config,
  pkgs,
  inputs,
  ...
}:
let
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
  services = {
    emacs = {
      enable = true;
      install = true;
      package = emacs;
      defaultEditor = true;
    };
    # :grammar support through language tool
    languagetool.enable = true;
  };

  environment.sessionVariables = {
    EDITOR = "emacseditor";
    PATH = [ "\${XDG_CONFIG_HOME}/emacs/bin" ];
  };

  environment.systemPackages =
    with pkgs;
    [
      emacs

      #native-comp emacs needs 'as' binary from binutils
      binutils

      zstd # for undo-fu-session/undo-tree compression

      ## Module dependencies
      # :checkers spell
      (aspellWithDicts (
        ds: with ds; [
          en
          en-computers
          en-science
        ]
      ))
      # :lookup
      wordnet

      # :tools editorconfig
      editorconfig-core-c # per-project style config

      # :tools lookup & :lang org +roam
      sqlite

      # :formatting
      dockfmt
      libxml2
      nodePackages.prettier

      # :tools lsp
      copilot-language-server
      dockerfile-language-server
      github-mcp-server
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      nodePackages.yaml-language-server
      inputs.mcp-nixos.packages."${pkgs.system}".default

      # :copilot
      nodejs

      # :lang markdown
      python3Packages.grip

    ]
    ++ [ inputs.nixd.packages."${pkgs.system}".nixd ]; # :tools lsp mode for nix

  system.userActivationScripts = {
    installDoomEmacs = ''
      source ${config.system.build.setEnvironment}
      if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
        git clone https://github.com/doomemacs/doomemacs.git "$XDG_CONFIG_HOME/emacs"
        git clone https://github.com/brianmcgillion/doomd.git "$XDG_CONFIG_HOME/doom"
      fi
    '';
  };
}
