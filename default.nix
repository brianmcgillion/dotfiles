# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Build the flake-compat URL from the lock node's own owner/repo (like
# shell.nix does) — hardcoding an owner breaks whenever the locked rev only
# exists in a fork.
(import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    inherit (lock.nodes.flake-compat.locked)
      owner
      repo
      rev
      narHash
      ;
  in
  fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = narHash;
  }
) { src = ./.; }).defaultNix
