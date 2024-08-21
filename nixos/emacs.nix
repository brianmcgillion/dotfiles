{
  config,
  pkgs,
  inputs,
  ...
}:
{
  services.emacs.enable = false;
  services.emacs.package =
    with pkgs;
    ((emacsPackagesFor emacs29-pgtk).emacsWithPackages (
      epkgs: with epkgs; [
        vterm
        pdf-tools
        org-pdftools
      ]
    ));

  environment.sessionVariables = {
    EDITOR = "emacs";
    PATH = [ "\${XDG_CONFIG_HOME}/emacs/bin" ];
  };

  # :grammar support through language tool
  services.languagetool.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      ((emacsPackagesFor emacs29-pgtk).emacsWithPackages (
        epkgs: with epkgs; [
          vterm
          pdf-tools
          org-pdftools
        ]
      ))

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

      # :formating
      dockfmt
      libxml2
      nodePackages.prettier

      # : treemacs
      python3

      # :copilot
      nodejs

      # :lang markdown
      python3.pkgs.grip

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
