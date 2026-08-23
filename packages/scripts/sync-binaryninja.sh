#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Re-pin the Binary Ninja hash in this checkout.
#
# Staging the zip into the nix store is no longer this script's job: the package
# and its modules moved to seclab-pkgs, where `stage-required-files` handles the
# requiredFiles/ drop-box. This only rewrites the
# `features.development.binaryninja.sha256` assignment that a host config
# carries, because that lives here and cannot be edited inside a flake input.
#
# Usage:
#   sync-binaryninja <base32-sha256>
#   sync-binaryninja --from <path/to/binaryninja_linux_dev_ultimate.zip>
#
# Environment:
#   PRJ_ROOT  dotfiles checkout (set by the devshell; else ~/.dotfiles)
#
# Requires: nix (nix-hash), git

usage() {
  sed -n '/^# Usage:/,/^#$/p' "$0" | sed 's/^# \?//'
}

if [ $# -eq 0 ]; then
  usage >&2
  exit 2
fi

case "$1" in
--from)
  [ $# -ge 2 ] || {
    echo "sync-binaryninja: --from needs a path" >&2
    exit 2
  }
  [ -f "$2" ] || {
    echo "sync-binaryninja: no such file: $2" >&2
    exit 1
  }
  new="$(nix-hash --type sha256 --flat --base32 "$2")"
  ;;
-h | --help)
  usage
  exit 0
  ;;
*) new="$1" ;;
esac

dotfiles="${PRJ_ROOT:-$HOME/.dotfiles}"
[ -d "$dotfiles" ] || {
  echo "sync-binaryninja: no such checkout: $dotfiles" >&2
  exit 1
}

# Find the single file carrying the pin. Failing loudly on 0 or >1 beats
# rewriting the wrong host by accident.
mapfile -t files < <(grep -rl 'binaryninja' --include='*.nix' "$dotfiles" |
  xargs -r grep -l 'sha256 = "' 2>/dev/null || true)

if [ "${#files[@]}" -eq 0 ]; then
  echo "sync-binaryninja: no file under $dotfiles sets binaryninja sha256" >&2
  exit 1
fi
if [ "${#files[@]}" -gt 1 ]; then
  echo "sync-binaryninja: the pin appears in more than one file:" >&2
  printf '  %s\n' "${files[@]}" >&2
  echo "Edit the right one by hand." >&2
  exit 1
fi

nixfile="${files[0]}"
old="$(grep -oP 'sha256 = "\K[^"]+' "$nixfile")"

if [ "$old" = "$new" ]; then
  echo "sync-binaryninja: pin already current ($new)"
  exit 0
fi

sed -i -E 's|(sha256 = ")[^"]*(")|\1'"$new"'\2|' "$nixfile"
echo "sync-binaryninja: updated pin in $(realpath --relative-to="$dotfiles" "$nixfile")"
echo "  $old"
echo "  -> $new"
