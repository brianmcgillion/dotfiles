{pkgs, ...}: {
  # A selection of packages that are used in most standard environments
  # Building plugins
  # providing plugins (nodejs)
  #
  home.packages = with pkgs; [
    # Generic code
    cmake
    coreutils
    gnumake
    #nodejs
    nodePackages.npm
    bibtool
    llvm
    gcc
    nixos-generators
    clang-tools
    bear
    bcompare
  ];
}
