{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    #Documentation
    #linux-manual
    man-pages
    man-pages-posix
    #    nix-doc
    act
    inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.default
    github-copilot-cli
  ];
}
