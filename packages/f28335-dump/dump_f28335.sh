#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Two-pass memory dump of a TMS320F28335 via TI UniFlash + XDS200:
#   pass 1 - halt-only        -> $OUTDIR/dump-halt/
#   pass 2 - reset, then halt -> $OUTDIR/dump-reset/
#
# Each region read is its own `dslite memory` invocation (connect, halt, read,
# disconnect). The reset pass issues a CPU reset via `dslite flash --reset=$RESET_OP`
# before the read loop; the device may run for a few hundred ms between reads, so
# RAM regions reflect "shortly after reset" rather than a perfectly-frozen reset
# state. Flash/OTP/Boot ROM are non-volatile and unaffected.
#
# Environment overrides:
#   CCXML     path to target configuration .ccxml (default: bundled XDS200+F28335 config)
#   OUTDIR    parent output directory (default: $PWD/dumps/<timestamp>)
#   RESET_OP  reset-operation index for 'dslite flash --reset' (default: 0 = "CPU Reset"
#             on the F28335; run 'dslite flash --config=$CCXML --list-resets' to enumerate).
#             An index is used rather than the name because the dslite wrapper re-splits
#             space-containing arguments like "CPU Reset" into stray flash operands.

set -euo pipefail

CCXML="${CCXML:-@default_ccxml@}"
OUTDIR="${OUTDIR:-$PWD/dumps/$(date +%Y%m%d-%H%M%S)}"

if [[ ! -f $CCXML ]]; then
  echo "error: ccxml not found: $CCXML" >&2
  exit 1
fi

if ! command -v dslite >/dev/null 2>&1; then
  echo "error: 'dslite' not on PATH (enable features.development.uniflash)" >&2
  exit 1
fi

if pgrep -x DSLite >/dev/null; then
  echo "warning: another DSLite process is running and will hold the XDS probe:" >&2
  pgrep -af DSLite >&2
  echo "kill it before continuing (e.g. 'pkill -x DSLite'); aborting." >&2
  exit 1
fi

mkdir -p "$OUTDIR"
echo "ccxml:     $CCXML"
echo "dump root: $OUTDIR"

# Region table: name | address | length-in-words | page | notes
# page is the C28x address-space tag for the --range syntax: 0 = PROGRAM, 1 = DATA.
# Most regions are unified (page 0 == page 1); peripheral frames are DATA-only.
#
# Naming follows TI's published memory-map terminology (see SPRS439 datasheet
# and SPRUFB0 peripheral reference):
#   - m0/m1 SARAM, L0..L7 SARAM (8 separate captures, TI-documented granularity)
#   - L0..L3 SARAM program-page mirrors (4 separate captures at 0x3F8000-0x3FBFFF)
#   - PF0..PF3 peripheral frames (PF0 captures the wider 0x000800-0x001FFF range
#     to include Flash/CSM/CPU-Timer/PIE/ADC regs that sit just past TI's strict
#     0x800-word PF0 boundary)
#   - adc_cal + partid are the only TI-factory OTP words the debugger memory
#     map exposes (per f28335.gel: 0x380080-0x380088 ADC_cal, 0x380090 PARTID);
#     the rest of 0x380080-0x3800FF is unmapped and a wider read is rejected
#     with "Memory map prevented reading ...".
#   - user_otp is the User-Programmable OTP at 0x380400
regions=(
  "m0_saram            0x000000   0x0400  0   M0 SARAM (1 KW = 2 KB)"
  "m1_saram            0x000400   0x0400  0   M1 SARAM (1 KW = 2 KB)"
  "pf0                 0x000800   0x1800  1   PF0 + adj regs: PIE/Flash/CSM/CPU-Timer/ADC/XINTF (DATA, 6 KW)"
  "pf3                 0x005000   0x1000  1   PF3: McBSP regs (DATA, 4 KW)"
  "pf1                 0x006000   0x1000  1   PF1: eCAN/ePWM/eCAP/eQEP/GPIO regs (DATA, 4 KW)"
  "pf2                 0x007000   0x1000  1   PF2: SysCtrl/SCI/SPI/I2C/ADC regs (DATA, 4 KW)"
  "saram_l0            0x008000   0x1000  0   L0 SARAM (4 KW)"
  "saram_l1            0x009000   0x1000  0   L1 SARAM (4 KW)"
  "saram_l2            0x00a000   0x1000  0   L2 SARAM (4 KW)"
  "saram_l3            0x00b000   0x1000  0   L3 SARAM (4 KW)"
  "saram_l4            0x00c000   0x1000  0   L4 SARAM (4 KW)"
  "saram_l5            0x00d000   0x1000  0   L5 SARAM (4 KW)"
  "saram_l6            0x00e000   0x1000  0   L6 SARAM (4 KW)"
  "saram_l7            0x00f000   0x1000  0   L7 SARAM (4 KW)"
  "flash               0x300000   0x40000 0   Flash sectors A..H (256 KW) - blocked if CSM locked"
  "adc_cal             0x380080   0x0009  0   TI-OTP ADC_cal data (9 W; only mapped TI-OTP window)"
  "partid              0x380090   0x0001  0   TI-OTP PARTID (1 W)"
  "user_otp            0x380400   0x0400  0   User OTP (1 KW) - blocked if CSM locked"
  "saram_l0_pgm        0x3f8000   0x1000  0   L0 SARAM program-page mirror (4 KW)"
  "saram_l1_pgm        0x3f9000   0x1000  0   L1 SARAM program-page mirror (4 KW)"
  "saram_l2_pgm        0x3fa000   0x1000  0   L2 SARAM program-page mirror (4 KW)"
  "saram_l3_pgm        0x3fb000   0x1000  0   L3 SARAM program-page mirror (4 KW)"
  "bootrom             0x3fe000   0x2000  0   Boot ROM (8 KW)"
  # CSM password locations - read LAST so a locked device doesn't trigger CSM lock
  # on the rest of the run.
  "csm_pwl             0x33FFF8   0x0008  0   CSM password locations (last)"
)

dump_one() {
  local dir=$1 name=$2 addr=$3 len=$4 page=$5
  local out="$dir/${name}.bin"
  local log="$dir/${name}.log"
  local range="${addr}@${page},${len}"

  printf '  %-18s  range=%s\n' "$name" "$range"
  if dslite --mode memory \
    --config="$CCXML" \
    --range="$range" \
    --size=16 \
    --output="$out" \
    --verbose >"$log" 2>&1; then
    printf '    ok (%d bytes)\n' "$(stat -c%s "$out")"
  else
    local rc=$?
    printf '    FAILED (exit %d) - see %s\n' "$rc" "$log" >&2
    return $rc
  fi
}

run_pass() {
  local dir=$1
  mkdir -p "$dir"
  local fail=0
  for row in "${regions[@]}"; do
    # shellcheck disable=SC2086
    set -- $row
    if ! dump_one "$dir" "$1" "$2" "$3" "$4"; then
      fail=$((fail + 1))
    fi
  done
  return $fail
}

echo
echo "=== pass 1: halt -> $OUTDIR/dump-halt ==="
halt_fail=0
run_pass "$OUTDIR/dump-halt" || halt_fail=$?

echo
RESET_OP="${RESET_OP:-0}"
echo "=== issuing CPU reset via 'dslite flash --reset=$RESET_OP' ==="
reset_log="$OUTDIR/reset.log"
if dslite --mode flash --config="$CCXML" --reset="$RESET_OP" --verbose >"$reset_log" 2>&1; then
  echo "reset complete"
else
  echo "warning: reset command failed (exit $?); see $reset_log" >&2
  echo "tip: run 'dslite flash --config=$CCXML --list-resets' with the target connected"
  echo "to enumerate reset operations, then set RESET_OP to the desired index."
fi

echo
echo "=== pass 2: reset -> $OUTDIR/dump-reset ==="
reset_fail=0
run_pass "$OUTDIR/dump-reset" || reset_fail=$?

echo
if ((halt_fail == 0 && reset_fail == 0)); then
  echo "done. both passes dumped under $OUTDIR"
else
  echo "done with failures: halt=$halt_fail reset=$reset_fail; inspect *.log" >&2
  exit 1
fi

# Reconstruct the reset-pass dump into a linkable COFF + disassembly. The
# halt-pass image diverges from chip state (DSS halt perturbs some
# peripheral registers) so it is intentionally skipped here.
# Skip with RECONSTRUCT=0 if you only want raw .bin output.
if [[ ${RECONSTRUCT:-1} != 0 ]] && command -v reconstruct_f28335 >/dev/null 2>&1; then
  echo
  echo "=== reconstruct: $OUTDIR/dump-reset ==="
  if reconstruct_f28335 "$OUTDIR/dump-reset"; then
    echo "reconstruct: ok"
  else
    rc=$?
    echo "reconstruct: FAILED (exit $rc); raw dumps are still under $OUTDIR/dump-reset" >&2
    exit $rc
  fi
fi

# Stitch all dumped regions into a single 8 MiB chip-image suitable for
# Binary Ninja (base address 0, BN_byte = 2 * chip_word convention).
# Skip with STITCH=0.
if [[ ${STITCH:-1} != 0 ]] && command -v stitch_f28335 >/dev/null 2>&1; then
  echo
  echo "=== stitch: $OUTDIR/dump-reset ==="
  if stitch_f28335 "$OUTDIR/dump-reset"; then
    echo "stitch: ok"
  else
    rc=$?
    echo "stitch: FAILED (exit $rc); raw dumps are still under $OUTDIR/dump-reset" >&2
    exit $rc
  fi
fi
