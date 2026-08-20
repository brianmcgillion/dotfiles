#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# `dev` - enter this repo's portable devshells from any directory.
#
# packages/scripts/default.nix wraps this with writeShellApplication and exports
# DEV_SHELLS (names, from nix/devshells/names.nix) and DEV_FLAKE_FALLBACK (the
# ${self} store path, baked in at rebuild time).
#
# Each shell gets its own profile under $XDG_STATE_HOME/nix/profiles/. A profile
# generation is an indirect GC root, which is what survives the weekly
# nix-collect-garbage (modules/profiles/common.nix); generations older than
# PRUNE_AGE are dropped after each use.

readonly PRUNE_AGE=30d
profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"

die() {
  printf 'dev: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: dev <stack> [--fast] [nix develop args...]
       dev list
       dev init <stack> [--force]
       dev tmp <stack>
       dev forget <stack>
       dev update [<stack> | --all]

<stack> is one shell, or several comma-separated to layer them: later
entries take PATH precedence, and every shell's env vars are kept.

Shells: ${DEV_SHELLS}

  dev rust                  enter the rust shell
  dev rust -c cargo build   run one command in it and exit
  dev rust --fast           enter from the built profile without re-evaluating
  dev c-cpp,reverse-engineering
                            layer both toolchains in one session
  dev init rust             write .envrc in \$PWD so direnv loads it on cd
  dev tmp rust              same, but ephemeral - removed when the shell exits
  dev forget rust           drop the GC root and free the closure
EOF
}

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

# Split "a,b" into the caller's `names` array (caller declares `local -a names`;
# bash dynamic scoping). Not a subshell: `die` inside $(...) would exit only the
# subshell and hand the caller an empty array.
parse_shells() {
  local spec=${1:-} name
  [ -n "$spec" ] || die "needs a shell name (use a,b to stack)"
  IFS=',' read -ra names <<<"$spec"
  for name in "${names[@]}"; do
    [ -n "$name" ] || die "empty shell name in '$spec'"
    require_shell "$name"
  done
}

# Live checkout wins so edits to nix/devshells/ apply without a rebuild; the
# pinned store path covers hosts with no checkout. Nix only sees git-tracked
# files, so a brand-new shell must be `git add`-ed before it resolves.
flake_ref() {
  local dotfiles="${DOTFILES_DIR:-$HOME/.dotfiles}"
  if [ -d "$dotfiles/.git" ]; then
    printf '%s' "$dotfiles"
  else
    printf '%s' "$DEV_FLAKE_FALLBACK"
  fi
}

# nix-env form, not `nix profile wipe-history`: profiles made by
# `nix develop --profile` have no manifest.json and the latter refuses them.
prune() {
  nix-env --profile "$1" --delete-generations "$PRUNE_AGE" >/dev/null 2>&1 || true
}

build_profile() {
  local name=$1 profile status=0
  profile=$(profile_for "$name")
  mkdir -p "$profile_dir"
  # Capture the status explicitly: callers use `build_profile x || ...`, which
  # disables errexit for the whole body, so a bare failure here would fall
  # through and the function would return prune's status (always 0).
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

# nix-direnv layers `use flake` rather than replacing, so one line per shell
# gives an editor every toolchain in the stack at once.
envrc_use_lines() {
  local name
  for name in "$@"; do
    # shellcheck disable=SC2016  # literal on purpose: direnv expands it at load
    printf 'use flake "${DOTFILES_DIR:-$HOME/.dotfiles}#%s"\n' "$name"
  done
}

cmd_init() {
  local spec=${1:-} force=${2:-}
  local -a names
  parse_shells "$spec"

  if [ -e .envrc ] && [ "$force" != "--force" ]; then
    die ".envrc already exists here; pass --force to overwrite"
  fi

  {
    printf '# Managed by "dev init %s" - see ~/.dotfiles/nix/devshells/\n' "$spec"
    [ "${#names[@]}" -gt 1 ] &&
      printf '# Shells layer in order; later entries take PATH precedence.\n'
    envrc_use_lines "${names[@]}"
  } >.envrc
  printf 'dev: wrote %s/.envrc for %s\n' "$PWD" "$spec"

  if command -v direnv >/dev/null 2>&1; then
    direnv allow
  else
    printf 'dev: direnv not on PATH; run "direnv allow" yourself\n' >&2
  fi
}

# `dev tmp` exists for editors: emacsclient inherits the daemon's environment,
# so `dev <shell>` is invisible to it and envrc.el reads only an .envrc on disk.
# The line-1 marker records the owning PID and layout dir so a SIGKILLed session
# (where the trap cannot run) is identifiable and cleanable afterwards.
readonly TMP_MARKER='# dev-tmp'

# True when .envrc here is a `dev tmp` file whose owner is gone. Both the PID
# and the layout dir must be checked, or a `dev list` in a second terminal would
# delete the .envrc of a live session in the same directory.
tmp_envrc_owner_dead() {
  local first pid layout
  [ -f .envrc ] || return 1
  first=$(head -n1 .envrc 2>/dev/null) || return 1
  case "$first" in "$TMP_MARKER "*) ;; *) return 1 ;; esac

  pid=${first##*pid=}
  pid=${pid%% *}
  layout=${first##*layout=}
  layout=${layout%% *}

  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && [ -d "$layout" ] && return 1
  return 0
}

# Order matters: direnv's allow entry is keyed on sha256(path + content), so it
# cannot be located once the file is gone - `prune` sweeps entries by path.
tmp_cleanup() {
  local envrc=$1 layout=$2
  rm -f "$envrc"
  [ -n "$layout" ] && rm -rf "$layout"
  if command -v direnv >/dev/null 2>&1; then
    direnv prune >/dev/null 2>&1 || true
  fi
}

cmd_tmp() {
  local spec=${1:-} envrc layout name
  local -a names
  parse_shells "$spec"
  command -v direnv >/dev/null 2>&1 || die "tmp needs direnv on PATH"

  if [ -e .envrc ]; then
    if tmp_envrc_owner_dead; then
      printf 'dev: clearing an orphaned dev tmp .envrc from a previous run\n' >&2
      rm -f .envrc
    else
      die ".envrc already exists here; dev tmp will not touch it"
    fi
  fi

  # nix-direnv's GC roots live in the layout dir and die with it, so root the
  # closures in the normal profiles first.
  for name in "${names[@]}"; do
    build_profile "$name"
  done

  envrc="$PWD/.envrc"
  layout=$(mktemp -d "${TMPDIR:-/tmp}/dev-tmp-${names[0]}-XXXXXX")

  # direnv_layout_dir is a lowercase shell variable read from inside .envrc -
  # direnv 2.37 has no env-var equivalent. Redirecting it keeps .direnv out of
  # the project, so .envrc is the only file that ever appears here.
  {
    printf '%s pid=%s layout=%s\n' "$TMP_MARKER" "$$" "$layout"
    printf '# Ephemeral - created by "dev tmp %s", removed when that shell exits.\n' "$spec"
    printf '# Safe to delete at any time.\n'
    printf 'direnv_layout_dir=%s\n' "$layout"
    envrc_use_lines "${names[@]}"
  } >"$envrc"

  # shellcheck disable=SC2064  # expand now: the trap must capture today's paths
  trap "tmp_cleanup '$envrc' '$layout'" EXIT INT TERM HUP

  direnv allow "$envrc"
  printf 'dev: ephemeral %s environment in %s (exit the shell to remove it)\n' "$spec" "$PWD"

  # Not exec'd - the trap has to outlive the child.
  "${SHELL:-bash}" -i || true
}

cmd_forget() {
  local spec=${1:-} name profile
  local -a names
  parse_shells "$spec"
  for name in "${names[@]}"; do
    profile=$(profile_for "$name")
    if [ ! -e "$profile" ]; then
      printf 'dev: %s is not built, skipping\n' "$name" >&2
      continue
    fi
    # Generation symlinks are siblings of the profile link; leaving them behind
    # would keep the closure rooted.
    rm -f "$profile" "$profile"-*-link
    printf 'dev: dropped %s (closure is now collectable)\n' "$name"
  done
}

cmd_update() {
  local target=${1:-}
  [ -n "$target" ] || die "update needs a shell name or --all"
  if [ "$target" = "--all" ]; then
    # Keep going past a failure so one broken shell does not hide the rest.
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
  local -a names
  parse_shells "$target"
  local name
  for name in "${names[@]}"; do
    build_profile "$name"
  done
}

# Enter one shell, or nest a stack: nix develop A -c nix develop B -c <cmd>.
# Nesting, not merging: PATH precedence resolves collisions and env vars
# accumulate. A merged shell would not build at all - devshell composes packages
# with pkgs.buildEnv, and c-cpp's clang-wrapper and reverse-engineering's
# binutils both ship bin/ld.gold.
enter() {
  local spec=$1 status=0 fast=0 name profile
  shift
  local -a names argv=()
  parse_shells "$spec"

  if [ "${1:-}" = "--fast" ]; then
    fast=1
    shift
  fi

  [ "$fast" -eq 1 ] || mkdir -p "$profile_dir"

  for name in "${names[@]}"; do
    profile=$(profile_for "$name")
    [ "${#argv[@]}" -eq 0 ] || argv+=(-c)
    if [ "$fast" -eq 1 ]; then
      [ -e "$profile" ] || die "shell '$name' is not built yet; run 'dev $name' once first"
      argv+=(nix develop "$profile")
    else
      argv+=(nix develop --profile "$profile" "$(flake_ref)#${name}")
    fi
  done
  argv+=("$@")

  # Not exec'd: the prunes have to run once the shell exits.
  "${argv[@]}" || status=$?
  if [ "$fast" -eq 0 ]; then
    for name in "${names[@]}"; do
      prune "$(profile_for "$name")"
    done
  fi
  return "$status"
}

main() {
  local sub=${1:-}

  # Clear a crashed `dev tmp` session's leftovers. Gated on the owner being
  # gone, so live sessions are untouched.
  if [ "$sub" != "tmp" ] && tmp_envrc_owner_dead; then
    local first layout
    first=$(head -n1 .envrc)
    layout=${first##*layout=}
    layout=${layout%% *}
    printf 'dev: removing orphaned dev tmp .envrc in %s\n' "$PWD" >&2
    tmp_cleanup "$PWD/.envrc" "$layout"
  fi

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
  tmp)
    shift
    cmd_tmp "$@"
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
    shift
    enter "$sub" "$@"
    ;;
  esac
}

main "$@"
