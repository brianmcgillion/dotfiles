# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./shell/default.nix
    ./apps/default.nix
    ./development/default.nix
    ./browsers/default.nix
    ./security/default.nix
  ];

  options.modules.home = {
    # Shell modules
    shell = {
      enable = mkEnableOption "Shell configuration and utilities";
      basic = mkEnableOption "Basic shell utilities";
      fzf = mkEnableOption "FZF fuzzy finder";
      git = mkEnableOption "Git configuration";
      kitty = mkEnableOption "Kitty terminal";
      terminator = mkEnableOption "Terminator terminal";
      ghostty = mkEnableOption "Ghostty terminal";
      tmux = mkEnableOption "Tmux terminal multiplexer";
    };

    # Apps modules
    apps = {
      enable = mkEnableOption "Applications";
      chat = mkEnableOption "Chat applications";
      documents = mkEnableOption "Document applications";
    };

    # Development modules
    development = {
      enable = mkEnableOption "Development tools";
      base = mkEnableOption "Base development tools";
      graphical = mkEnableOption "Graphical development tools";
      embedded = mkEnableOption "Embedded development tools";
    };

    # Browser modules
    browsers = {
      enable = mkEnableOption "Web browsers";
      firefox = mkEnableOption "Firefox browser";
      chrome = mkEnableOption "Chrome browser";
      chromium = mkEnableOption "Chromium browser";
    };

    # Security modules
    security = {
      enable = mkEnableOption "Security tools";
      ssh = mkEnableOption "SSH configuration";
      gpg = mkEnableOption "GPG configuration";
    };
  };

  config = { };
}
