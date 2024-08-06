{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alejandra
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
    usbutils
    pciutils
    #Documentation
    linux-manual
    man-pages
    man-pages-posix
    #    nix-doc
    nix-tree
    globalprotect-openconnect
  ];
}
