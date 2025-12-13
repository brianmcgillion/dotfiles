# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  # A selection of packages that are used in most standard environments
  # Building plugins
  # providing plugins (nodejs)
  #
  home.packages = [
    # keep-sorted start
    pkgs.bear
    pkgs.bibtool
    pkgs.clang-tools
    pkgs.cmake
    pkgs.coreutils
    pkgs.gcc
    pkgs.gnumake
    pkgs.llvm
    pkgs.nix-fast-build
    pkgs.nix-update
    pkgs.nixos-generators
    pkgs.nixpkgs-review
    pkgs.nodePackages_latest.nodejs
    pkgs.optinix
    pkgs.uv
    # keep-sorted end
  ];

  programs = {
    pandoc.enable = true;
  };
}
