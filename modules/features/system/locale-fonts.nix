# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Locale and font configuration
#
# Configures system locale settings and installs a comprehensive font collection
# for desktop systems with international and symbol support.
#
# Locale settings:
# - Default: en_US.UTF-8
# - Regional settings: en_IE.UTF-8 (Ireland)
#   - Address, identification, measurement formats
#   - Monetary, name, numeric formats
#   - Paper size, telephone, time formats
#
# Font packages:
# - Carlito, Vegur: NixOS default fonts
# - Liberation: Metric-compatible with Arial, Times New Roman, Courier
# - Font Awesome: Icon font
# - FiraCode Nerd Font: Programming font with ligatures and powerline
# - Nerd Font Symbols: Programming symbols and icons
# - Noto Color Emoji: Google's emoji font
# - Source Serif: Adobe's serif font family
# - FiraGO: Modern sans-serif with extended character support
# - Symbola: Unicode symbol font
#
# Default fonts:
# - Sans-serif: FiraGO
# - Serif: Source Serif 4
# - Monospace: FiraCode Nerd Font
# - Emoji: Noto Color Emoji, Font Awesome
#
# Usage:
#   features.system.locale-fonts.enable = true;
#
# Enabled by default in: profile-client
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.system.locale-fonts;
in
{
  options.features.system.locale-fonts = {
    enable = lib.mkEnableOption "locale and font configuration";
  };

  config = lib.mkIf cfg.enable {
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_IE.UTF-8";
      LC_IDENTIFICATION = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETARY = "en_IE.UTF-8";
      LC_NAME = "en_IE.UTF-8";
      LC_NUMERIC = "en_IE.UTF-8";
      LC_PAPER = "en_IE.UTF-8";
      LC_TELEPHONE = "en_IE.UTF-8";
      LC_TIME = "en_IE.UTF-8";
    };

    fonts = {
      packages = with pkgs; [
        carlito
        vegur
        liberation_ttf
        font-awesome
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
        noto-fonts-color-emoji
        source-serif
        fira-go
        fira-sans
        symbola
      ];

      enableDefaultPackages = true;

      fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [ "FiraGO" ];
          serif = [ "Source Serif 4" ];
          monospace = [ "FiraCode Nerd Font" ];
          emoji = [
            "Noto Color Emoji"
            "Font Awesome"
          ];
        };
      };
    };
  };
}
