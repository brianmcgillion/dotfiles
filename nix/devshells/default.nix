# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Devshell aggregator.
#
# ./dotfiles.nix defines devShells.default (working *on* this repo); every name
# in ./names.nix defines a portable language environment reachable from any
# directory via `dev <name>`.
#
# On the numtide/devshell pin (reviewed 2026-08-19, decision: keep):
# upstream main has not moved since 2026-01-19 - our lock IS its HEAD, so we are
# current and upstream is dormant (renovate PRs from Mar-Jun 2026 unmerged, no
# maintainer replies). It is not deprecated or archived, and numtide itself is
# healthy (treefmt, system-manager, blueprint all shipping). Risk is low: this is
# an eval-time library with no runtime component, it emits standard `devShells`,
# and packages/scripts/dev.sh only ever calls `nix develop <flake>#<name>` - so
# nothing downstream would notice an implementation swap.
#
# Migrating is NOT worth it right now because flake.nix:125 sets
# `gp-gui.inputs.devshell.follows = "devshell"` - gp-gui uses devshell itself, so
# the input stays in the lock regardless of what these files do.
#
# If it ever breaks: use pkgs.mkShellNoCC (not mkShell, which is
# stdenv.mkDerivation and injects a C compiler). The six language shells only use
# `packages` plus plain `value` env entries, so they convert mechanically; only
# ./dotfiles.nix is real work, as its `commands` menu has no mkShell equivalent.
{ inputs, ... }:
{
  imports = [
    inputs.devshell.flakeModule
    ./dotfiles.nix
  ]
  ++ map (name: ./. + "/${name}.nix") (import ./names.nix);
}
