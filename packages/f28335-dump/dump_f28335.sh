#!/usr/bin/env bash
# Two-pass memory dump of a TMS320F28335 via TI UniFlash + XDS200:
#   pass 1 - halt-only        -> $OUTDIR/dump-halt/
#   pass 2 - reset, then halt -> $OUTDIR/dump-reset/
#
# Each region read is its own `dslite memory` invocation (connect, halt, read,
# disconnect). The reset pass issues a system reset via `dslite flash --before=Reset`
# before the read loop; the device may run for a few hundred ms between reads, so
# RAM regions reflect "shortly after reset" rather than a perfectly-frozen reset
# state. Flash/OTP/Boot ROM are non-volatile and unaffected.
#
# Environment overrides:
#   CCXML   path to target configuration .ccxml (default: bundled XDS200+F28335 config)
#   OUTDIR  parent output directory (default: $PWD/dumps/<timestamp>)

set -euo pipefail

CCXML="${CCXML:-@default_ccxml@}"
OUTDIR="${OUTDIR:-$PWD/dumps/$(date +%Y%m%d-%H%M%S)}"

if [[ ! -f "$CCXML" ]]; then
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
regions=(
    "m0_saram            0x000000   0x0400  0   M0 SARAM (2 KB)"
    "m1_saram            0x000400   0x0400  0   M1 SARAM (2 KB)"
    "pf0_regs            0x000800   0x1800  1   PF0: Flash/CSM/CPU-Timer/PIE regs (DATA only, 12 KB)"
    "l0_l7_saram         0x008000   0x8000  0   L0..L7 SARAM contiguous (64 KB)"
    "pf3_mcbsp           0x005000   0x1000  1   PF3: McBSP regs (DATA only)"
    "pf1_ecan_pwm        0x006000   0x1000  1   PF1: eCAN/ePWM/eCAP/eQEP regs (DATA only)"
    "pf2_sysctrl         0x007000   0x1000  1   PF2: SysCtrl/SCI/SPI/I2C/ADC regs (DATA only)"
    "flash               0x300000   0x40000 0   Flash sectors A..H (512 KB) - blocked if CSM locked"
    "tiotp_adc_cal       0x380080   0x0009  0   TI-OTP ADC calibration"
    "tiotp_partid        0x380090   0x0001  0   TI-OTP part ID"
    "user_otp            0x380400   0x0400  0   User OTP (2 KB) - blocked if CSM locked"
    "saram_mirror        0x3F8000   0x4000  0   L0..L3 SARAM mirror (32 KB)"
    "bootrom             0x3FE000   0x2000  0   Boot ROM (16 KB)"
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
            fail=$((fail+1))
        fi
    done
    return $fail
}

echo
echo "=== pass 1: halt -> $OUTDIR/dump-halt ==="
halt_fail=0
run_pass "$OUTDIR/dump-halt" || halt_fail=$?

echo
echo "=== issuing system reset via 'dslite flash --before=Reset' ==="
reset_log="$OUTDIR/reset.log"
if dslite --mode flash --config="$CCXML" --before=Reset --verbose >"$reset_log" 2>&1; then
    echo "reset complete"
else
    echo "warning: reset command failed (exit $?); see $reset_log" >&2
    echo "tip: try 'dslite flash --config=$CCXML --list-ops' with the target connected"
    echo "to find the correct reset operation name for this device."
fi

echo
echo "=== pass 2: reset -> $OUTDIR/dump-reset ==="
reset_fail=0
run_pass "$OUTDIR/dump-reset" || reset_fail=$?

echo
if (( halt_fail == 0 && reset_fail == 0 )); then
    echo "done. both passes dumped under $OUTDIR"
else
    echo "done with failures: halt=$halt_fail reset=$reset_fail; inspect *.log" >&2
    exit 1
fi
