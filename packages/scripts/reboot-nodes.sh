#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
#
# `reboot-nodes` - reboot the deploy-rs target hosts that need it.
#
# nix/devshells/dotfiles.nix wraps this with writeShellApplication and supplies
# two generated pieces, both derived from self.deploy.nodes (nix/deployments.nix)
# so the fleet list can never drift from the one deploy-rs itself uses:
#
#   REBOOT_NODES  space-separated node names
#   node_ssh      node_ssh <node> <cmd...> - ssh as that node's deploy user with
#                 that node's sshOpts, i.e. the builder key rather than the
#                 YubiKeys, so a fleet-wide run costs no touches
#
# `nixos-rebuild switch` activates units but leaves the running kernel, initrd
# and modules alone, and nothing surfaces that afterwards. So by default each
# node is probed and rebooted only when those actually differ; --force skips
# the probe.

readonly PROG=reboot-nodes

die() {
  printf '%s: %s\n' "$PROG" "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $PROG [-f|--force] [-y|--yes] [node...]

Reboot deploy-rs target hosts. With no node arguments every node is considered.
A node is rebooted only when its booted kernel, initrd or kernel modules differ
from the activated system.

  -f, --force   reboot without probing whether it is needed
  -y, --yes     do not ask for confirmation
  -h, --help    show this help

Nodes: ${REBOOT_NODES}
EOF
}

force=0
assume_yes=0
targets=()

while [ $# -gt 0 ]; do
  case $1 in
  -f | --force) force=1 ;;
  -y | --yes) assume_yes=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    targets+=("$@")
    break
    ;;
  -*) die "unknown option '$1' (try --help)" ;;
  *) targets+=("$1") ;;
  esac
  shift
done

read -ra all_nodes <<<"$REBOOT_NODES"

if [ ${#targets[@]} -eq 0 ]; then
  targets=("${all_nodes[@]}")
else
  # Reject a typo now rather than after the confirmation prompt.
  for want in "${targets[@]}"; do
    found=0
    for known in "${all_nodes[@]}"; do
      if [ "$want" = "$known" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      die "unknown node '$want' (have: ${REBOOT_NODES})"
    fi
  done
fi

# Runs on the target, so it must not expand locally - hence single quotes.
# Emits "<changed components>|<booted kernel>|<activated kernel>".
# shellcheck disable=SC2016  # literal on purpose: the remote shell expands it
readonly PROBE='
booted=/run/booted-system
current=/run/current-system
changed=
for f in kernel initrd kernel-modules; do
  if [ "$(readlink -f "$booted/$f" 2>/dev/null)" \
     != "$(readlink -f "$current/$f" 2>/dev/null)" ]; then
    changed="$changed $f"
  fi
done
for d in "$current"/kernel-modules/lib/modules/*; do
  [ -e "$d" ] && new=${d##*/}
  break
done
printf "%s|%s|%s\n" "${changed# }" "$(uname -r)" "${new:-}"
'

needed=()
failures=0
skipped=0

for node in "${targets[@]}"; do
  if [ "$force" -eq 1 ]; then
    printf '%-10s … reboot forced\n' "$node"
    needed+=("$node")
    continue
  fi

  if ! probe_out=$(node_ssh "$node" "$PROBE" 2>/dev/null); then
    printf '%-10s … UNREACHABLE\n' "$node"
    failures=$((failures + 1))
    continue
  fi

  IFS='|' read -r changed booted activated <<<"$probe_out"

  if [ -z "$changed" ]; then
    printf '%-10s … up to date (kernel %s), skipping\n' "$node" "$booted"
    skipped=$((skipped + 1))
    continue
  fi

  if [ -n "$activated" ] && [ "$booted" != "$activated" ]; then
    printf '%-10s … kernel %s -> %s, reboot needed\n' "$node" "$booted" "$activated"
  else
    printf '%-10s … changed:%s, reboot needed\n' "$node" "$changed"
  fi
  needed+=("$node")
done

if [ ${#needed[@]} -eq 0 ]; then
  printf '\nNothing to reboot.\n'
  if [ "$failures" -ne 0 ]; then
    exit 1
  fi
  exit 0
fi

if [ "$assume_yes" -eq 0 ]; then
  printf '\nReboot %d node(s): %s [y/N] ' "${#needed[@]}" "${needed[*]}"
  read -r reply || reply=
  case $reply in
  y | Y | yes | YES) ;;
  *) die "aborted" ;;
  esac
fi

issued=0
for node in "${needed[@]}"; do
  # Deliberately not a bare `systemctl reboot`: that tears the connection down
  # mid-command so ssh exits 255, which is indistinguishable from an auth or
  # network failure. Scheduling it lets ssh exit cleanly, so a non-zero status
  # here honestly means the reboot was never scheduled.
  if node_ssh "$node" systemd-run --on-active=2s \
    --timer-property=AccuracySec=100ms systemctl reboot >/dev/null 2>&1; then
    printf '%-10s … reboot issued\n' "$node"
    issued=$((issued + 1))
  else
    printf '%-10s … FAILED to schedule reboot\n' "$node"
    failures=$((failures + 1))
  fi
done

printf '\n%d issued, %d failed, %d skipped\n' "$issued" "$failures" "$skipped"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
