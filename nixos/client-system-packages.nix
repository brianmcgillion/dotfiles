{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    #Documentation
    #linux-manual
    man-pages
    man-pages-posix
    #    nix-doc
  ];
}
