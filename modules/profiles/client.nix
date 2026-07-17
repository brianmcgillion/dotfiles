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
# Enabled features by default (see the features block below — it is the
# authoritative list): audio, desktop-manager, power-management, yubikey,
# sshd (hardened), docker, emacs, emacs-ui, greatfet, remarkable,
# saleae-logic, locale-fonts, remote-builders
#
# Note: SSH is enabled by default via the hardened features.security.sshd
# module (key-only auth, fail2ban). Disable per-host with:
#   features.security.sshd.enable = false;
{
  self,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # keep-sorted start
    ./common.nix
    inputs.gp-gui.nixosModules.default
    inputs.srvos.nixosModules.desktop
    self.nixosModules.feature-ai
    self.nixosModules.feature-audio
    self.nixosModules.feature-binaryninja
    self.nixosModules.feature-c2000-cgt
    self.nixosModules.feature-desktop-manager
    self.nixosModules.feature-docker
    self.nixosModules.feature-emacs
    self.nixosModules.feature-emacs-ui
    self.nixosModules.feature-fail2ban
    self.nixosModules.feature-greatfet
    self.nixosModules.feature-keyd
    self.nixosModules.feature-locale-fonts
    self.nixosModules.feature-power-management
    self.nixosModules.feature-remarkable
    self.nixosModules.feature-saleae-logic
    self.nixosModules.feature-sshd
    self.nixosModules.feature-stm32cubeprog
    self.nixosModules.feature-uniflash
    self.nixosModules.feature-wireguard
    self.nixosModules.feature-yubikey
    self.nixosModules.scripts
    self.nixosModules.user-root
    # keep-sorted end
  ];

  config = {
    # Set profile target
    common.profile.target = "client";

    # Ghaf project binary cache (used with nix-fast-build)
    # Priority 50 ensures cache.nixos.org (default priority 40) is checked first
    nix.settings = {
      extra-substituters = [
        "https://ghaf-dev.cachix.org?priority=50"
        # AI agent tooling from numtide/llm-agents.nix (npm/bun builds land here).
        "https://cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };

    # Enable client features by default
    features = {
      desktop = {
        audio.enable = lib.mkDefault true;
        desktop-manager.enable = lib.mkDefault true;
        power-management.enable = lib.mkDefault true;
        yubikey.enable = lib.mkDefault true;
      };
      development = {
        binaryninja.enable = lib.mkDefault false;
        docker.enable = lib.mkDefault true;
        emacs.enable = lib.mkDefault true;
        emacs-ui.enable = lib.mkDefault true;
        greatfet.enable = lib.mkDefault true;
        remarkable.enable = lib.mkDefault true;
        saleae-logic.enable = lib.mkDefault true;
      };
      security = {
        # Hardened SSH (key-only auth + fail2ban) — same feature module the
        # servers use, so clients never run sshd with stock settings.
        sshd.enable = lib.mkDefault true;
      };
      system = {
        locale-fonts.enable = lib.mkDefault true;
        # Development machines build via the work builders
        remote-builders.enable = lib.mkDefault true;
      };
    };

    # Enable gp-gui
    programs.gp-gui.enable = lib.mkDefault true;

    nixpkgs = {
      overlays = [
        # gp-gui overlay provides gp-gui-wrapper and gpclient-wrapper
        inputs.gp-gui.overlays.default
        # emacs-git and friends (only clients run the emacs feature)
        inputs.emacs-overlay.overlays.default
      ];
      # Waivers for client applications only
      config.permittedInsecurePackages = [
        "qtwebengine-5.15.19" # needed for globalprotect-vpn
        "jitsi-meet-1.0.8792"
      ];
    };

    nix.settings = {
      # Keep build-time dependencies and derivations around on dev machines
      # (they blunt GC on servers for no benefit)
      keep-outputs = true;
      keep-derivations = true;
    };

    # Cross-building/emulation for development work
    boot.binfmt.emulatedSystems = [
      "riscv64-linux"
      "aarch64-linux"
    ];

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
        # Use systemd-resolved for DNS (required for Nebula split-horizon DNS)
        dns = "systemd-resolved";
      };
    };

    # Services
    services = {
      fwupd.enable = true;
      # Enable systemd-resolved for split-horizon DNS
      # This allows per-interface DNS configuration via resolvectl
      # Disable mDNS in resolved since avahi handles it (avoids "another mDNS stack" warning)
      resolved = {
        enable = true;
        settings.Resolve = {
          LLMNR = true;
          MulticastDNS = false;
        };
      };
      # Enable Bluetooth for wireplumber/PipeWire audio
      blueman.enable = true;
      # Avahi for mDNS with nss-mdns support
      avahi = {
        enable = true;
        nssmdns4 = true;
      };
    };

    systemd.services = {
      # Disable ModemManager - not needed and interferes with serial consoles
      # Both services must be disabled to prevent D-Bus activation on reboot
      # See: https://github.com/NixOS/nixpkgs/issues/41055
      ModemManager.enable = false;
      # https://github.com/NixOS/nixpkgs/issues/180175
      NetworkManager-wait-online.enable = false;
    };

    hardware = {
      # Enable Bluetooth hardware support
      bluetooth.enable = true;
      # Clients get the full (unfree) firmware set for wifi/bt/peripherals;
      # servers make do with the redistributable set from profile-common.
      enableAllFirmware = true;
      # ZSA keyboard support (Ergodox, Moonlander, Voyager)
      keyboard.zsa.enable = true;
    };

    # Client-specific packages
    environment.systemPackages = [
      # keep-sorted start
      pkgs.act
      pkgs.ccstatusline
      pkgs.ccusage
      pkgs.claude-agent-acp
      pkgs.claude-code
      pkgs.coderabbit-cli
      pkgs.github-copilot-cli
      pkgs.keymapp
      pkgs.man-pages
      pkgs.man-pages-posix
      pkgs.pciutils
      pkgs.rebiber
      pkgs.solaar
      pkgs.usbutils
      pkgs.wally-cli
      # keep-sorted end
    ]
    ++ [
      inputs.nix-ai.packages."${pkgs.stdenv.hostPlatform.system}".default
      #inputs.globalprotect-openconnect.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    # Developer documentation
    documentation = {
      dev.enable = true;
    };
  };
}
