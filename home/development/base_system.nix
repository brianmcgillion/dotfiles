{ pkgs, ... }:
{
  # A selection of packages that are used in most standard environments
  # Building plugins
  # providing plugins (nodejs)
  #
  home.packages = with pkgs; [
    # Generic code
    cmake
    coreutils
    gnumake
    nodePackages.npm
    bibtool
    llvm
    gcc
    nixos-generators
    clang-tools
    bear
    nixpkgs-review
    optinix
    nix-update
    nix-fast-build
  ];

  programs = {
    pandoc.enable = true;
  };
}
