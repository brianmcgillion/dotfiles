{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    cachix
    wget
    curl
    git
    htop
    nix-info
    wireguard-tools
    google-chrome
  ];
}
