# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Main module entry point - exports all modules
#
# Modules are exported as paths (not imported values) so the module system
# can deduplicate them when the same module is reachable via two routes
# (e.g. profile-common exported here and imported relatively by
# profile-client/profile-server).
_: {
  flake.nixosModules = {
    # Profiles
    profile-common = ./profiles/common.nix;
    profile-client = ./profiles/client.nix;
    profile-server = ./profiles/server.nix;

    # AI features
    feature-ai = ./features/ai;

    # Desktop features
    feature-audio = ./features/desktop/audio.nix;
    feature-desktop-manager = ./features/desktop/desktop-manager.nix;
    feature-keyd = ./features/desktop/keyd.nix;
    feature-power-management = ./features/desktop/power-management.nix;
    feature-yubikey = ./features/desktop/yubikey.nix;

    # Development features
    feature-binaryninja = ./features/development/binaryninja.nix;
    feature-c2000-cgt = ./features/development/c2000-cgt.nix;
    feature-docker = ./features/development/docker.nix;
    feature-emacs = ./features/development/emacs.nix;
    feature-emacs-ui = ./features/development/emacs-ui.nix;
    feature-greatfet = ./features/development/greatfet.nix;
    feature-remarkable = ./features/development/remarkable.nix;
    feature-saleae-logic = ./features/development/saleae-logic.nix;
    feature-stm32cubeprog = ./features/development/stm32cubeprog.nix;
    feature-uniflash = ./features/development/uniflash.nix;

    # Networking features
    feature-nebula = ./features/networking/nebula.nix;
    feature-wireguard = ./features/networking/wireguard.nix;

    # Security features
    feature-hardening = ./features/security/hardening.nix;
    feature-fail2ban = ./features/security/fail2ban.nix;
    feature-sshd = ./features/security/sshd.nix;

    # System features
    feature-locale-fonts = ./features/system/locale-fonts.nix;
    feature-xdg = ./features/system/xdg.nix;
    feature-system-packages = ./features/system/packages.nix;
    feature-github-token = ./features/system/github-token.nix;
    feature-remote-builders = ./features/system/remote-builders.nix;

    # Hardware
    hardware-nvidia = ./hardware/nvidia.nix;

    # Users (non-flake-parts modules)
    user-root = ./users/root.nix;
    user-groups = ./users/groups.nix;
  };

  # Import brian user as flake-parts module (exports both nixosModules and homeModules)
  imports = [ ./users/brian ];
}
