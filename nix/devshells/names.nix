# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Portable devshells reachable from anywhere via the `dev` command.
#
# Single source of truth for the shell names. Two consumers:
#   - ./default.nix           derives its imports from this list, so a name
#                             without a matching ./<name>.nix is an eval error
#                             rather than silent drift.
#   - packages/scripts/dev.sh gets the list baked in at build time (via
#                             packages/scripts/default.nix) for `dev list` and
#                             bash completion, without forcing a flake-parts
#                             perSystem evaluation on every nixos-rebuild.
#
# Invariant: entry == filename in this directory == devshells.<attr> it defines.
#
# `default` lives in ./dotfiles.nix and is deliberately absent: it is the
# repo-maintenance shell, not a portable language environment.
[
  # keep-sorted start
  "c-cpp"
  "embedded"
  "go"
  "python"
  "reverse-engineering"
  "rust"
  # keep-sorted end
]
