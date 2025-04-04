# SPDX-License-Identifier: Apache-2.0
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption;
in {
  imports = [
    ./audio.nix
    ./client-system-packages.nix
    ./desktop-manager.nix
    ./emacs.nix
    ./emacs-ui.nix
    ./hardening.nix
    ./locale-font.nix
    ./nebula.nix
    ./system-packages.nix
    ./xdg.nix
    ./yubikey.nix
    ./fail2ban.nix
    ./sshd.nix
    # Users module removed from here
  ];

  options.setup.modules = {
    audio = mkEnableOption "Audio module with PipeWire";
    client = mkEnableOption "Client system configuration";
    server = mkEnableOption "Server system configuration";
    emacs = mkEnableOption "Emacs editor and packages";
    emacs-ui = mkEnableOption "Emacs UI configuration";
    desktop = mkEnableOption "Desktop environment";
    yubikey = mkEnableOption "YubiKey support";
    fail2ban = mkEnableOption "Fail2ban intrusion prevention";
    sshd = mkEnableOption "SSH daemon configuration";
    hardening = mkEnableOption "System security hardening";
    xdg = mkEnableOption "XDG Base Directory specification";
  };

  config = {
    # Configure modules based on setup options
    modules.audio.enable = config.setup.modules.audio;
    modules.emacs.enable = config.setup.modules.emacs;
    
    # Enable client-specific modules when setup.modules.client is true
    modules.client-system-packages.enable = config.setup.modules.client;
    modules.desktop-manager.enable = config.setup.modules.desktop;
    modules.emacs-ui.enable = config.setup.modules.emacs-ui;
    modules.locale-font.enable = config.setup.modules.client; 
    modules.yubikey.enable = config.setup.modules.yubikey;
    
    # Enable server-specific modules when setup.modules.server is true
    modules.fail2ban.enable = config.setup.modules.fail2ban;
    modules.sshd.enable = config.setup.modules.sshd;
    
    # Modules that can be explicitly enabled
    modules.hardening.enable = config.setup.modules.hardening;
    modules.system-packages.enable = true; # Always enable base packages
    modules.xdg.enable = config.setup.modules.xdg;
    modules.my-nebula.enable = true; # Always enable nebula module
  };
}
