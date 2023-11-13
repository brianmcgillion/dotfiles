# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: {
  i18n.defaultLocale = "en_US.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.utf8";
    LC_IDENTIFICATION = "en_IE.utf8";
    LC_MEASUREMENT = "en_IE.utf8";
    LC_MONETARY = "en_IE.utf8";
    LC_NAME = "en_IE.utf8";
    LC_NUMERIC = "en_IE.utf8";
    LC_PAPER = "en_IE.utf8";
    LC_TELEPHONE = "en_IE.utf8";
    LC_TIME = "en_IE.utf8";
  };

  fonts.packages = with pkgs; [
    # Fonts
    carlito # NixOS
    vegur # NixOS
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome # Icons
    # TODO replace nerdFonts (see emacs config)
    (nerdfonts.override {
      # Nerdfont Icons override
      fonts = ["FiraCode"];
    })
  ];
}
