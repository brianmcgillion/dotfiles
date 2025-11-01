# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
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
    nodePackages_latest.nodejs
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
