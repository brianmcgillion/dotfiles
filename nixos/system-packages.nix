{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system-packages;
in
{
  options.modules.system-packages = {
    enable = mkEnableOption "Base system packages";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      cachix
      wget
      curl
      git
      htop
      nix-info
      wireguard-tools
      tree
      file
      binutils
      lsof
      dnsutils
      netcat
      nix-tree
      zellij
      ghostty.terminfo
    ];
  };
}
