# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  # A selection of packages that are used in most standard environments
  # Building plugins
  # providing plugins (nodejs)
  #
  # nodejs comes from the emacs feature module system-wide on clients.
  home.packages = [
    # keep-sorted start
    pkgs.bear
    #pkgs.bibtool # broken upstream
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
    pkgs.optinix
    pkgs.ripgrep-all # search inside PDFs, archives, ... (client-only: pulls ffmpeg/pandoc/poppler)
    pkgs.uv
    pkgs.xxd
    # keep-sorted end
  ];

  programs = {
    pandoc.enable = true;
  };
}
