_: {
  flake.nixosModules = {
    audio = import ./audio.nix;
    desktop-manager = import ./desktop-manager.nix;
    emacs = import ./emacs.nix;
    emacs-ui = import ./emacs-ui.nix;
    hardening = import ./hardening.nix;
    libreoffice = import ./libreoffice.nix;
    locale-font = import ./locale-font.nix;
    nebula = import ./nebula.nix;
    system-packages = import ./system-packages.nix;
    xdg = import ./xdg.nix;
    yubikey = import ./yubikey.nix;
    fail2ban = import ./fail2ban.nix;
    sshd = import ./sshd.nix;
  };
}
