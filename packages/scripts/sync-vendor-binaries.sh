#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Record which vendor binaries the Nextcloud sync has delivered, and stage each
# into the nix store, where seclab-pkgs' requireFile looks for it.
#
# Writes modules/profiles/vendor-binaries.json; the client profile enables the
# matching feature for every entry, so review and commit the diff.
#
# Usage:
#   sync-vendor-binaries
#
# Environment:
#   VENDOR_BINARIES  source directory (default ~/Documents/binaries)
#   PRJ_ROOT         dotfiles checkout (set by the devshell; else ~/.dotfiles)
#
# Requires: nix (nix-store, nix-hash)

src="${VENDOR_BINARIES:-$HOME/Documents/binaries}"
dotfiles="${PRJ_ROOT:-$HOME/.dotfiles}"
manifest="$dotfiles/modules/profiles/vendor-binaries.json"

# A missing directory would otherwise write an empty manifest and disable every
# vendor feature on every client.
[ -d "$src" ] || {
  echo "sync-vendor-binaries: no such directory: $src" >&2
  exit 1
}
[ -d "$dotfiles" ] || {
  echo "sync-vendor-binaries: no such checkout: $dotfiles" >&2
  exit 1
}

# Manifest key, then the file's glob relative to $src.
artifacts=(
  binaryninja "binary-ninja/binaryninja_linux_dev_ultimate.zip"
  stm32cubeprogrammer "STM32CubeProgrammer/SetupSTM32CubeProgrammer_linux_64.zip"
  uniflash "uniflash/uniflash_sl.*.run"
)

entries=()
for ((i = 0; i < ${#artifacts[@]}; i += 2)); do
  key="${artifacts[i]}"
  mapfile -t found < <(compgen -G "$src/${artifacts[i + 1]}" || true)
  case "${#found[@]}" in
  0) continue ;;
  1) ;;
  *)
    echo "sync-vendor-binaries: more than one $key file; keep only the one to install:" >&2
    printf '  %s\n' "${found[@]}" >&2
    exit 1
    ;;
  esac

  file="${found[0]}"
  nix-store --add-fixed sha256 "$file" >/dev/null
  sha256="$(nix-hash --type sha256 --flat --base32 "$file")"
  entries+=("$(printf '  "%s": { "path": "%s", "sha256": "%s" }' "$key" "${file#"$src"/}" "$sha256")")
  echo "sync-vendor-binaries: $key <- ${file#"$src"/}"
done

{
  echo "{"
  for ((i = 0; i < ${#entries[@]}; i++)); do
    if ((i < ${#entries[@]} - 1)); then
      echo "${entries[i]},"
    else
      echo "${entries[i]}"
    fi
  done
  echo "}"
} >"$manifest"

echo "sync-vendor-binaries: wrote $(realpath --relative-to="$dotfiles" "$manifest")"
