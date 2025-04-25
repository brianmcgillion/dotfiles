{ pkgs, ... }:
{
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
  ];
}
