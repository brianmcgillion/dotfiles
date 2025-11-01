# SPDX-License-Identifier: MIT
# Emacs UI and graphical tools
#
# Provides graphical and document processing tools for Emacs.
# Complements the base emacs module with UI-specific dependencies.
#
# Features:
# - ImageMagick for image processing (image-dired)
# - TeX Live (scheme-medium) for LaTeX editing and org-mode exports
# - GnuTLS for secure network connections
# - Graphviz for diagram generation (org-mode, PlantUML)
# - Gnuplot for plotting and data visualization
# - Wayland clipboard support (wl-clipboard)
#
# Usage:
#   features.development.emacs-ui.enable = true;
#
# Enabled by default in: profile-client
#
# Requires: features.development.emacs
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.emacs-ui;
in
{
  options.features.development.emacs-ui = {
    enable = lib.mkEnableOption "Emacs UI and graphical tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      imagemagick
      texlive.combined.scheme-medium
      gnutls
      graphviz
      gnuplot
      wl-clipboard
    ];
  };
}
