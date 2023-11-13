{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  services.emacs.enable = false;
  services.emacs.package = with pkgs; ((emacsPackagesFor emacs29-pgtk).emacsWithPackages
    (epkgs: [epkgs.vterm epkgs.pdf-tools epkgs.org-pdftools]));

  #TODO Remove rec not needed here
  environment.sessionVariables = rec {
    EDITOR = "emacs";
    PATH = ["$XDG_CONFIG_HOME/emacs/bin"];
  };

  #fonts.packages = [pkgs.emacs-all-the-icons-fonts];

  # :grammar support through language tool
  services.languagetool.enable = true;

  environment.systemPackages = with pkgs; [
    ((emacsPackagesFor emacs29-pgtk).emacsWithPackages
      (epkgs: [
        epkgs.vterm
        epkgs.pdf-tools
        epkgs.org-pdftools
      ]))

    #native-comp emacs needs 'as' binary from binutils
    binutils

    # TODO Use some secrets managment tool to lock sensitive conf files.
    gnutls # for TLS connectivity

    imagemagick # for image-dired
    zstd # for undo-fu-session/undo-tree compression

    ## Module dependencies
    # :checkers spell
    (aspellWithDicts (ds: with ds; [en en-computers en-science]))
    # :lookup
    wordnet

    # :tools editorconfig
    editorconfig-core-c # per-project style config

    # :tools lookup & :lang org +roam
    sqlite

    # :lang latex & :lang org (latex previews)
    texlive.combined.scheme-full

    # :lang org & :org-roam2
    graphviz
    gnuplot
    # :lang org +dragndrop
    wl-clipboard
    maim

    # :formating
    dockfmt

    # :lang markdown
    python3.pkgs.grip
    # (python3.withPackages (ps: with ps; [ grip ]))
  ]; # Dependencies

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
