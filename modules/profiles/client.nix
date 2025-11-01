# SPDX-License-Identifier: MIT
# Client (desktop/laptop) profile
#
# This profile configures systems for interactive desktop/laptop use.
# It extends the common profile with graphical environment support.
#
# Included features:
# - GNOME desktop environment with GDM display manager
# - PipeWire audio system
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
  config,
  ...
}:
{
  imports = [
    ./common.nix
    self.nixosModules.feature-audio
    self.nixosModules.feature-desktop-manager
    self.nixosModules.feature-emacs
    self.nixosModules.feature-emacs-ui
    self.nixosModules.feature-locale-fonts
    self.nixosModules.feature-yubikey
    self.nixosModules.feature-sshd
    self.nixosModules.feature-fail2ban
    self.nixosModules.scripts
    inputs.srvos.nixosModules.desktop
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    # Enable client features by default
    features = {
      desktop = {
        audio.enable = lib.mkDefault true;
        desktop-manager.enable = lib.mkDefault true;
        yubikey.enable = lib.mkDefault true;
      };
      development = {
        emacs.enable = lib.mkDefault true;
        emacs-ui.enable = lib.mkDefault true;
      };
      system = {
        locale-fonts.enable = lib.mkDefault true;
      };
    };

    # Bootloader configuration for UEFI systems
    boot.loader = {
      systemd-boot.enable = lib.mkDefault true;
      systemd-boot.configurationLimit = lib.mkDefault 5;
      efi.canTouchEfiVariables = lib.mkDefault true;
      efi.efiSysMountPoint = lib.mkDefault "/boot/efi";
    };

    # Network configuration
    networking = {
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
      globalprotect = {
        enable = true;
        csdWrapper = "${pkgs.openconnect}/libexec/openconnect/hipreport.sh";
      };
      resolved.enable = false;
    };

    # Client-specific packages
    environment.systemPackages =
      with pkgs;
      [
        # Hardware tools
        usbutils
        pciutils

        # Documentation
        man-pages
        man-pages-posix

        # Development tools
        act
        github-copilot-cli

        # ZSA keyboard tools
        wally-cli
        keymapp

        # User packages
        aider-chat-full
        rebiber
        globalprotect-openconnect
      ]
      ++ [ inputs.nix-ai.packages."${pkgs.stdenv.hostPlatform.system}".default ];

    hardware.keyboard.zsa.enable = true;

    # Developer documentation
    documentation = {
      dev.enable = true;
    };

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs self;
      };
      users.brian = {
        imports = [
          ../../home/profiles/client.nix
          inputs.nix-index-database.homeModules.nix-index
        ];
      };
    };
  };
}
