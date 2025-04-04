_: {
  flake.nixosModules = {
    # Single top-level module that manages all other modules
    system-config = import ./system-config.nix;
    
    # Keep individual modules for direct import if needed
    audio = import ./audio.nix;
    client-system-packages = import ./client-system-packages.nix;
    desktop-manager = import ./desktop-manager.nix;
    emacs = import ./emacs.nix;
    emacs-ui = import ./emacs-ui.nix;
    hardening = import ./hardening.nix;
    locale-font = import ./locale-font.nix;
    my-nebula = import ./nebula.nix;
    system-packages = import ./system-packages.nix;
    xdg = import ./xdg.nix;
    yubikey = import ./yubikey.nix;
    fail2ban = import ./fail2ban.nix;
    sshd = import ./sshd.nix;
  };
}
