{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.emacs-ui;
in {
  options.modules.emacs-ui = {
    enable = mkEnableOption "Emacs UI configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      imagemagick # for image-dired

      # :lang latex & :lang org (latex previews)
      texlive.combined.scheme-medium

      # TODO Use some secrets management tool to lock sensitive conf files.
      gnutls # for TLS connectivity

      # :lang org & :org-roam2
      graphviz
      gnuplot
      # :lang org +dragndrop
      wl-clipboard
      #maim
    ];
  };
}
