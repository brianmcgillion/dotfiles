#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# `dev` - enter one of this repo's portable devshells from any directory.
#
# Wrapped by packages/scripts/default.nix (writeShellApplication), which
# prepends the shebang, `set -euo pipefail` and two exported variables:
#
#   DEV_SHELLS         space-separated shell names, from nix/devshells/names.nix
#   DEV_FLAKE_FALLBACK ${self} store path, baked in at nixos-rebuild time
#
# Flake resolution prefers the live ~/.dotfiles checkout so that editing
# nix/devshells/<name>.nix takes effect on the next `dev <name>` with no
# rebuild, and falls back to DEV_FLAKE_FALLBACK on hosts without the checkout.
#
# CAVEAT: Nix only sees files that git knows about. A brand-new
# nix/devshells/<name>.nix must be `git add`-ed before `dev` can find it.
#
# Each shell is installed into its own Nix profile under
# $XDG_STATE_HOME/nix/profiles/dev-<name>. Creating a profile generation
# registers an indirect GC root, which is what keeps the closure alive across
# the weekly `nix-collect-garbage --delete-older-than 7d` (see
# modules/profiles/common.nix). Generations older than 30 days are pruned after
# each use so old toolchains do not pin disk forever; `dev forget <name>` drops
# a shell entirely.

readonly PRUNE_AGE=30d
profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"

die() {
  printf 'dev: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: dev <shell> [--fast] [nix develop args...]
       dev list
       dev init <shell> [--force]
       dev forget <shell>
       dev update [<shell> | --all]

Shells: ${DEV_SHELLS}

  dev rust                  enter the rust shell
  dev rust -c cargo build   run one command in it and exit
  dev rust --fast           enter from the built profile without re-evaluating
  dev init rust             write .envrc in \$PWD so direnv loads it on cd
  dev forget rust           drop the GC root and free the closure
EOF
}

# Space-separated -> array, so membership tests do not word-split unquoted.
shells() {
  local -a names
  read -ra names <<<"$DEV_SHELLS"
  printf '%s\n' "${names[@]}"
}

require_shell() {
  local name=$1
  if ! shells | grep -qxF -- "$name"; then
    die "unknown shell '$name' (have: ${DEV_SHELLS})"
  fi
}

profile_for() {
  printf '%s/dev-%s' "$profile_dir" "$1"
}

# Live checkout wins; the pinned store path is the fallback for hosts that have
# no ~/.dotfiles (servers) or a checkout that has been moved away.
flake_ref() {
  local dotfiles="${DOTFILES_DIR:-$HOME/.dotfiles}"
  if [ -d "$dotfiles/.git" ]; then
    printf '%s' "$dotfiles"
  else
    printf '%s' "$DEV_FLAKE_FALLBACK"
  fi
}

# `nix profile wipe-history` refuses profiles that have no manifest.json, and
# `nix develop --profile` creates exactly that kind, so use the nix-env form.
prune() {
  nix-env --profile "$1" --delete-generations "$PRUNE_AGE" >/dev/null 2>&1 || true
}

build_profile() {
  local name=$1 profile status=0
  profile=$(profile_for "$name")
  mkdir -p "$profile_dir"
  # Capture the status rather than relying on errexit: this function is called
  # as `build_profile x || ...`, which disables errexit for its whole body, so
  # a bare `nix develop` failure would fall through and the function would
  # return prune's status (always 0) instead.
  nix develop --profile "$profile" "$(flake_ref)#${name}" --command true || status=$?
  prune "$profile"
  return "$status"
}

cmd_list() {
  local name profile state
  printf '%-22s %-14s %s\n' SHELL STATE FLAKE
  while read -r name; do
    profile=$(profile_for "$name")
    if [ -e "$profile" ]; then state=built; else state='not built'; fi
    printf '%-22s %-14s %s\n' "$name" "$state" "$(flake_ref)#${name}"
  done < <(shells)
}

cmd_init() {
  local name=${1:-} force=${2:-}
  [ -n "$name" ] || die "init needs a shell name"
  require_shell "$name"

  if [ -e .envrc ] && [ "$force" != "--force" ]; then
    die ".envrc already exists here; pass --force to overwrite"
  fi

  cat >.envrc <<EOF
# Managed by \`dev init ${name}\` - see ~/.dotfiles/nix/devshells/${name}.nix
use flake "\${DOTFILES_DIR:-\$HOME/.dotfiles}#${name}"
EOF
  printf 'dev: wrote %s/.envrc for shell %s\n' "$PWD" "$name"

  if command -v direnv >/dev/null 2>&1; then
    direnv allow
  else
    printf 'dev: direnv not on PATH; run "direnv allow" yourself\n' >&2
  fi
}

cmd_forget() {
  local name=${1:-} profile
  [ -n "$name" ] || die "forget needs a shell name"
  require_shell "$name"
  profile=$(profile_for "$name")
  [ -e "$profile" ] || die "shell '$name' is not built"
  # The generation symlinks are siblings of the profile link itself; leaving
  # them behind would keep the closure rooted.
  rm -f "$profile" "$profile"-*-link
  printf 'dev: dropped %s (closure is now collectable)\n' "$name"
}

cmd_update() {
  local target=${1:-}
  [ -n "$target" ] || die "update needs a shell name or --all"
  if [ "$target" = "--all" ]; then
    # One broken shell must not hide the state of the others, so keep going and
    # report at the end rather than letting errexit abort the loop.
    local name
    local -a failed=()
    while read -r name; do
      printf 'dev: building %s\n' "$name"
      build_profile "$name" || failed+=("$name")
    done < <(shells)
    if [ ${#failed[@]} -gt 0 ]; then
      printf 'dev: failed to build: %s\n' "${failed[*]}" >&2
      return 1
    fi
    printf 'dev: all shells built\n'
    return 0
  fi
  require_shell "$target"
  build_profile "$target"
}

enter() {
  local name=$1 profile status=0
  shift
  profile=$(profile_for "$name")

  if [ "${1:-}" = "--fast" ]; then
    shift
    [ -e "$profile" ] || die "shell '$name' is not built yet; run 'dev $name' once first"
    exec nix develop "$profile" "$@"
  fi

  mkdir -p "$profile_dir"
  # Not exec'd: the prune has to run once the interactive shell exits.
  nix develop --profile "$profile" "$(flake_ref)#${name}" "$@" || status=$?
  prune "$profile"
  return "$status"
}

main() {
  local sub=${1:-}
  case "$sub" in
  '' | -h | --help | help)
    usage
    ;;
  list)
    cmd_list
    ;;
  init)
    shift
    cmd_init "$@"
    ;;
  forget)
    shift
    cmd_forget "$@"
    ;;
  update)
    shift
    cmd_update "$@"
    ;;
  *)
    require_shell "$sub"
    shift
    enter "$sub" "$@"
    ;;
  esac
}

main "$@"
