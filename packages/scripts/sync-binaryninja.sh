#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Pin the local Binary Ninja zip and stage it into the Nix store.
#
# Binary Ninja ships as an out-of-tree zip that cannot be a flake input (a
# missing file would break `nix flake update` on every host). Instead
# home/development/binary-ninja.nix pulls it in with pkgs.requireFile, pinned by
# sha256. When you download a newer Binary Ninja build, run this script: it
# computes the new hash, adds the zip to the Nix store (so requireFile resolves)
# and rewrites the pinned sha256 in binary-ninja.nix.
#
# Usage:
#   sync-binaryninja
#
# Environment:
#   BINARYNINJA_ZIP  path to the zip (default below)
#   PRJ_ROOT         dotfiles checkout (set by the devshell; else ~/.dotfiles)
#
# Requires: nix (nix-hash, nix-store)

set -euo pipefail

zip="${BINARYNINJA_ZIP:-$HOME/projects/tools/binaryninja/binaryninja_linux_dev_ultimate.zip}"
dotfiles="${PRJ_ROOT:-$HOME/.dotfiles}"
nixfile="$dotfiles/home/development/binary-ninja.nix"

if [ ! -f "$zip" ]; then
  echo "sync-binaryninja: Binary Ninja zip not found at:" >&2
  echo "  $zip" >&2
  echo "Download it (or set the BINARYNINJA_ZIP env var) and re-run." >&2
  exit 1
fi

if [ ! -f "$nixfile" ]; then
  echo "sync-binaryninja: cannot find $nixfile (set \$PRJ_ROOT to the checkout)" >&2
  exit 1
fi

new="$(nix-hash --type sha256 --flat --base32 "$zip")"

# Stage the zip into the store so requireFile can resolve it. Idempotent:
# re-adding an already-present fixed-output path is a no-op.
nix-store --add-fixed sha256 "$zip" >/dev/null

old="$(grep -oP 'sha256 = "\K[^"]+' "$nixfile" || true)"

if [ "$old" = "$new" ]; then
  echo "sync-binaryninja: pin already current ($new)"
  exit 0
fi

sed -i -E 's|(sha256 = ")[^"]*(")|\1'"$new"'\2|' "$nixfile"
echo "sync-binaryninja: updated pin $old -> $new"
echo "sync-binaryninja: commit the change to $(basename "$nixfile")"
