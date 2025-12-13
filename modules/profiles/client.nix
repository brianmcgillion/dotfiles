# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Client (desktop/laptop) profile
#
# This profile configures systems for interactive desktop/laptop use.
# It extends the common profile with graphical environment support.
#
# Included features:
# - GNOME desktop environment with GDM display manager
# - PipeWire audio system
# - Docker containerization platform
# - Emacs with Doom configuration and UI tools
# - YubiKey hardware authentication support
# - Locale and font configuration
# - NetworkManager for network configuration
# - GlobalProtect VPN client
# - Firmware updates via fwupd
# - ZSA keyboard support (Ergodox, Moonlander)
# - Development tools and documentation
# - Home-manager integration for user environment
#
# Usage:
#   imports = [ self.nixosModules.profile-client ];
#
# Enabled features by default:
#   - features.desktop.audio
#   - features.desktop.desktop-manager
#   - features.desktop.yubikey
#   - features.development.docker
#   - features.development.emacs
#   - features.development.emacs-ui
#   - features.system.locale-fonts
#
# Note: SSH and fail2ban are available but not enabled by default.
# Enable SSH per-host with: features.security.sshd.enable = true;
{
  self,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    self.nixosModules.feature-audio
    self.nixosModules.feature-desktop-manager
    self.nixosModules.feature-docker
    self.nixosModules.feature-emacs
    self.nixosModules.feature-emacs-ui
    self.nixosModules.feature-locale-fonts
    self.nixosModules.feature-yubikey
    self.nixosModules.feature-sshd
    self.nixosModules.feature-fail2ban
    self.nixosModules.scripts
    inputs.srvos.nixosModules.desktop
    inputs.gp-gui.nixosModules.default
  ];

  config = {
    # Set profile target
    common.profile.target = "client";

    # Enable client features by default
    features = {
      desktop = {
        audio.enable = lib.mkDefault true;
        desktop-manager.enable = lib.mkDefault true;
        yubikey.enable = lib.mkDefault true;
      };
      development = {
        docker.enable = lib.mkDefault true;
        emacs.enable = lib.mkDefault true;
        emacs-ui.enable = lib.mkDefault true;
      };
      system = {
        locale-fonts.enable = lib.mkDefault true;
      };
    };

    # Enable gp-gui
    programs.gp-gui.enable = lib.mkDefault true;

    # Add gp-gui overlay to provide gp-gui-wrapper and gpclient-wrapper
    nixpkgs.overlays = [ inputs.gp-gui.overlays.default ];

    # Bootloader configuration for UEFI systems
    boot.loader = {
      systemd-boot.enable = lib.mkDefault true;
      systemd-boot.configurationLimit = lib.mkDefault 5;
      efi.canTouchEfiVariables = lib.mkDefault true;
      efi.efiSysMountPoint = lib.mkDefault "/boot/efi";
    };

    # Network configuration
    networking = {
      # Client systems use NetworkManager, not systemd-networkd
      useNetworkd = lib.mkForce false;
      networkmanager = {
        enable = true;
        plugins = [ pkgs.networkmanager-openconnect ];
      };
      firewall = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ 8080 ];
      };
    };

    # Services
    services = {
      openssh.enable = true;
      openssh.startWhenNeeded = false;
      fwupd.enable = true;
      # globalprotect = {
      #   enable = true;
      #   csdWrapper = "${pkgs.openconnect}/libexec/openconnect/hipreport.sh";
      # };
      resolved.enable = false;
    };

    # Client-specific packages
    environment.systemPackages =
      with pkgs;
      [
        # keep-sorted start
        act
        aider-chat-full
        github-copilot-cli
        keymapp
        man-pages
        man-pages-posix
        pciutils
        rebiber
        usbutils
        wally-cli
        # keep-sorted end
      ]
      ++ [
        inputs.nix-ai.packages."${pkgs.stdenv.hostPlatform.system}".default
        #inputs.globalprotect-openconnect.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];

    hardware.keyboard.zsa.enable = true;

    # Developer documentation
    documentation = {
      dev.enable = true;
    };
  };
}
