# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  # A selection of packages that are used in most standard environments
  # Building plugins
  # providing plugins (nodejs)
  #
  home.packages = with pkgs; [
    # keep-sorted start
    bear
    bibtool
    clang-tools
    cmake
    coreutils
    gcc
    gnumake
    llvm
    nix-fast-build
    nix-update
    nixos-generators
    nixpkgs-review
    nodePackages_latest.nodejs
    optinix
    # keep-sorted end
  ];

  programs = {
    pandoc.enable = true;
  };
}
