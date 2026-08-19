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
    #pkgs.bibtool # broken upstream
    pkgs.clang-tools
    pkgs.coreutils
    pkgs.gcc
    pkgs.gnumake
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

  # rga caches the text it extracts from PDFs/EPUBs in a SQLite DB under
  # ~/.cache/ripgrep-all, but only for blobs below `cache.max_blob_len`, which
  # defaults to 2MB *after zstd compression*. Research PDFs routinely exceed
  # that, and rga then re-runs poppler over them on every single search.
  xdg.configFile."ripgrep-all/config.jsonc".text = builtins.toJSON {
    cache.max_blob_len = 536870912; # 512M
  };

  programs = {
    pandoc.enable = true;
  };
}
