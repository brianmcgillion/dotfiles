# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Main module entry point - exports all modules
_: {
  flake.nixosModules = {
    # Profiles
    profile-common = import ./profiles/common.nix;
    profile-client = import ./profiles/client.nix;
    profile-server = import ./profiles/server.nix;

    # Desktop features
    feature-audio = import ./features/desktop/audio.nix;
    feature-desktop-manager = import ./features/desktop/desktop-manager.nix;
    feature-yubikey = import ./features/desktop/yubikey.nix;

    # Development features
    feature-docker = import ./features/development/docker.nix;
    feature-emacs = import ./features/development/emacs.nix;
    feature-emacs-ui = import ./features/development/emacs-ui.nix;

    # Networking features
    feature-nebula = import ./features/networking/nebula.nix;

    # Security features
    feature-hardening = import ./features/security/hardening.nix;
    feature-fail2ban = import ./features/security/fail2ban.nix;
    feature-sshd = import ./features/security/sshd.nix;

    # System features
    feature-locale-fonts = import ./features/system/locale-fonts.nix;
    feature-xdg = import ./features/system/xdg.nix;
    feature-system-packages = import ./features/system/packages.nix;
    feature-nix-settings = import ./features/system/nix-settings.nix;

    # Hardware
    hardware-nvidia = import ./hardware/nvidia.nix;

    # Users
    user-brian = import ./users/brian;
    user-root = import ./users/root.nix;
    user-groups = import ./users/groups.nix;
  };
}
