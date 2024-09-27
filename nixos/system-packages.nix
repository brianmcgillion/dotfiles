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
    gpauth
    gpclient
    tree
    file
    binutils
    lsof
    dnsutils
    netcat
    usbutils
    pciutils
    #Documentation
    linux-manual
    man-pages
    man-pages-posix
    #    nix-doc
    nix-tree
  ];
}
