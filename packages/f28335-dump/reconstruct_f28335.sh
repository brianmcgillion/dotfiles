#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Rebuild a TMS320F28335 dump (produced by dump_f28335) into a linkable COFF
# image plus disassembly. Reads each <region>.bin under <dump-dir>, emits a
# matching <region>.asm under <dump-dir>/reconstruct/, then drives cl2000
# (single-shot --run_linker) to produce <dump-dir>/link/dumped.{out,map} and
# dis2000 to produce <dump-dir>/dis/dumped.dis.
#
# Usage:
#   reconstruct_f28335 <dump-dir>
#
# <dump-dir> is the dir holding the *.bin files (typically the dump-reset/
# subtree of dump_f28335 output).
#
# Region table mirrors dump_f28335.sh exactly. csm_pwl.bin is intentionally
# omitted from the linker layout because it overlaps the top of .flash
# (chip 0x33FFF8..0x33FFFF) and would cause an overlap error.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: reconstruct_f28335 <dump-dir>" >&2
  exit 2
fi

DUMP_DIR=$(realpath "$1")
if [[ ! -d $DUMP_DIR ]]; then
  echo "error: not a directory: $DUMP_DIR" >&2
  exit 1
fi

for tool in cl2000 dis2000 od awk; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: '$tool' not on PATH" >&2
    exit 1
  fi
done

RECON_DIR="$DUMP_DIR/reconstruct"
LINK_DIR="$DUMP_DIR/link"
DIS_DIR="$DUMP_DIR/dis"
LOG_DIR="$DUMP_DIR/log"
mkdir -p "$RECON_DIR" "$LINK_DIR" "$DIS_DIR" "$LOG_DIR"

# Post-link analysis/verification helpers (Python). Resolved from nix-store paths
# when packaged (@classify_py@/@verify_py@ substituted by default.nix), else from
# alongside this script for a direct `bash reconstruct_f28335.sh` run. Both are
# OPTIONAL: with no python3 (or no c28x package for the classifier) the COFF/.dis
# still build. A byte-fidelity MISMATCH is the one fatal outcome (see below).
SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"
SELF_DIR="$(dirname "$SELF")"
CLASSIFY_PY="@classify_py@"
VERIFY_PY="@verify_py@"
[[ $CLASSIFY_PY == @* ]] && CLASSIFY_PY="$SELF_DIR/classify_f28335.py"
[[ $VERIFY_PY == @* ]] && VERIFY_PY="$SELF_DIR/verify_roundtrip.py"
PYTHON="${PYTHON:-python3}"

stamp=$(date +%Y%m%d-%H%M%S)
LOG="$LOG_DIR/${stamp}-reconstruct.log"
exec > >(tee -a "$LOG") 2>&1

echo "reconstruct_f28335: $DUMP_DIR"
echo "started: $(date -Iseconds)"
echo

# region table: bin-filename | section-name | linker-region | page | origin-word | length-words
# Mirrors dump_f28335.sh; names follow TI canonical terminology (SPRS439).
# .flash is special-cased to allow renamed variants (g103-flash.bin etc.) —
# handled in the loop below.
regions=(
  "m0_saram.bin        m0_saram        M0RAM          1 0x000000 0x0400"
  "m1_saram.bin        m1_saram        M1RAM          1 0x000400 0x0400"
  "pf0.bin             pf0             PF0            1 0x000800 0x1800"
  "pf3.bin             pf3             PF3            1 0x005000 0x1000"
  "pf1.bin             pf1             PF1            1 0x006000 0x1000"
  "pf2.bin             pf2             PF2            1 0x007000 0x1000"
  "saram_l0.bin        saram_l0        L0SARAM        1 0x008000 0x1000"
  "saram_l1.bin        saram_l1        L1SARAM        1 0x009000 0x1000"
  "saram_l2.bin        saram_l2        L2SARAM        1 0x00a000 0x1000"
  "saram_l3.bin        saram_l3        L3SARAM        1 0x00b000 0x1000"
  "saram_l4.bin        saram_l4        L4SARAM        1 0x00c000 0x1000"
  "saram_l5.bin        saram_l5        L5SARAM        1 0x00d000 0x1000"
  "saram_l6.bin        saram_l6        L6SARAM        1 0x00e000 0x1000"
  "saram_l7.bin        saram_l7        L7SARAM        1 0x00f000 0x1000"
  "flash.bin           flash           FLASH          0 0x300000 0x40000"
  "adc_cal.bin         adc_cal         ADC_CAL        0 0x380080 0x0009"
  "partid.bin          partid          PARTID         0 0x380090 0x0001"
  "user_otp.bin        user_otp        USER_OTP       0 0x380400 0x0400"
  "saram_l0_pgm.bin    saram_l0_pgm    L0SARAM_PGM    0 0x3f8000 0x1000"
  "saram_l1_pgm.bin    saram_l1_pgm    L1SARAM_PGM    0 0x3f9000 0x1000"
  "saram_l2_pgm.bin    saram_l2_pgm    L2SARAM_PGM    0 0x3fa000 0x1000"
  "saram_l3_pgm.bin    saram_l3_pgm    L3SARAM_PGM    0 0x3fb000 0x1000"
  "bootrom.bin         bootrom         BOOTROM        0 0x3fe000 0x2000"
)

# Emit one .asm from a .bin. Compresses runs of >=8 identical words into a
# .loop / .word / .endloop block; everything else is one .word per line with
# a trailing word-address comment.
encode_asm() {
  local bin=$1 out=$2 section=$3 origin=$4 page=$5
  local size_bytes
  size_bytes=$(stat -c%s "$bin")
  local size_words=$((size_bytes / 2))
  local origin_dec=$((origin))

  {
    cat <<HDR
;==============================================================
; ${section}.asm  --  f28335-dump reconstruct stage
;
; Source region : $(basename "$bin")
; Origin        : ${origin}  (word address)
; Length        : ${size_words} words (${size_bytes} bytes)
; Linker page   : ${page}
;
; Encoding      : raw little-endian word stream
; Compression   : runs of >= 8 identical words emit a
;                 .loop / .word VAL / .endloop block; everything else
;                 emits one .word per 16-bit value with the absolute
;                 word address as a trailing comment.
;==============================================================
	.sect	".${section}"
HDR

    od -An -v -tx2 -w2 "$bin" | awk -v origin="$origin_dec" '
      function flush(w, n, start,   i) {
        if (n >= 8) {
          printf "\t.loop\t%d\n", n
          printf "\t.word\t0x%s\n", w
          printf "\t.endloop\n"
        } else {
          for (i = 0; i < n; i++)
            printf "\t.word\t0x%s\t; 0x%06X\n", w, start + i
        }
      }
      BEGIN { addr = origin; prev = ""; run = 0 }
      {
        gsub(/[ \t]+/, "")
        word = toupper($0)
        if (word == "") next
        if (run == 0) {
          prev = word; run = 1
        } else if (word == prev) {
          run++
        } else {
          flush(prev, run, addr - run)
          prev = word; run = 1
        }
        addr++
      }
      END { if (run > 0) flush(prev, run, addr - run) }
    '
  } >"$out"
}

# Resolve the flash file: dump_f28335 writes "flash.bin", but some captures
# have it renamed to <variant>-flash.bin. Prefer flash.bin if present.
resolve_flash() {
  local default="$DUMP_DIR/flash.bin"
  if [[ -f $default ]]; then
    echo "$default"
    return 0
  fi
  local match
  match=$(find "$DUMP_DIR" -maxdepth 1 -name '*flash*.bin' ! -name 'flash_*' -type f | head -n1)
  if [[ -n $match ]]; then
    echo "$match"
    return 0
  fi
  return 1
}

# Build the linker MEMORY/SECTIONS file. Only includes regions whose .bin
# was actually present.
write_build_cmd() {
  local build_cmd="$RECON_DIR/build.cmd"
  {
    cat <<'HDR'
/* ============================================================
 * build.cmd  --  f28335-dump reconstruct stage
 *
 * Auto-generated linker command file for the reconstructed F28335
 * memory image. Feed this to cl2000 -z alongside the per-region
 * .asm files to produce a COFF object that dis2000 can decode.
 *
 * MEMORY block mirrors the dumped regions; PAGE 0 = program,
 * PAGE 1 = data (TI linker convention).
 *
 * csm_pwl is intentionally omitted because it lives inside .flash
 * (chip 0x33FFF8..0x33FFFF) and would overlap.
 * ============================================================ */

MEMORY
{
    PAGE 0:    /* program memory */
HDR

    # PAGE 0 entries
    for row in "${included_p0[@]}"; do
      IFS='|' read -r region origin length <<<"$row"
      printf '        %-14s : origin = %s, length = %s\n' "$region" "$origin" "$length"
    done

    cat <<'HDR'

    PAGE 1:    /* data memory */
HDR

    # PAGE 1 entries
    for row in "${included_p1[@]}"; do
      IFS='|' read -r region origin length <<<"$row"
      printf '        %-14s : origin = %s, length = %s\n' "$region" "$origin" "$length"
    done

    cat <<'MID'
}

SECTIONS
{
MID

    for row in "${included_sections[@]}"; do
      IFS='|' read -r section region page <<<"$row"
      printf '    .%-20s : > %-14s PAGE = %s\n' "$section" "$region" "$page"
    done

    echo "}"
  } >"$build_cmd"
}

# Walk the region table: emit .asm files + accumulate included-region lists.
included_p0=()
included_p1=()
included_sections=()
asm_inputs=()
missing=()

echo "=== encoding .asm files ==="
for row in "${regions[@]}"; do
  read -r bin_name section region page origin length <<<"$row"
  if [[ $bin_name == flash.bin ]]; then
    if ! bin=$(resolve_flash); then
      echo "  SKIP flash (no flash*.bin in $DUMP_DIR)"
      missing+=("$bin_name")
      continue
    fi
    printf '  %-22s -> %s\n' "$(basename "$bin")" "$section.asm"
  elif [[ ! -f "$DUMP_DIR/$bin_name" ]]; then
    echo "  SKIP $bin_name (not in $DUMP_DIR)"
    missing+=("$bin_name")
    continue
  else
    bin="$DUMP_DIR/$bin_name"
    printf '  %-22s -> %s\n' "$bin_name" "$section.asm"
  fi

  asm="$RECON_DIR/${section}.asm"
  encode_asm "$bin" "$asm" "$section" "$origin" "$page"
  asm_inputs+=("$asm")
  included_sections+=("$section|$region|$page")
  if [[ $page == 0 ]]; then
    included_p0+=("$region|$origin|$length")
  else
    included_p1+=("$region|$origin|$length")
  fi
done

if [[ ${#asm_inputs[@]} -eq 0 ]]; then
  echo "error: no region .bin files found under $DUMP_DIR" >&2
  exit 1
fi

echo
echo "=== writing build.cmd ==="
write_build_cmd
echo "  $RECON_DIR/build.cmd  ($(wc -l <"$RECON_DIR/build.cmd") lines)"

echo
echo "=== linking (cl2000 --run_linker) ==="
out_file="$LINK_DIR/dumped.out"
map_file="$LINK_DIR/dumped.map"
cl2000 \
  -v28 -ml -mt --float_support=fpu32 \
  --define=__TMS320F28335__ --abi=coffabi \
  "${asm_inputs[@]}" \
  -z \
  --output_file="$out_file" \
  --map_file="$map_file" \
  "$RECON_DIR/build.cmd"
echo "  $out_file  ($(stat -c%s "$out_file") bytes)"
echo "  $map_file  ($(wc -l <"$map_file") lines)"

echo
echo "=== disassembling (dis2000 --data_as_text --all) ==="
# NB: '--data_as_text' is required. A reconstructed COFF built from .word data is
# all STYP_DATA -- TI only marks STYP_TEXT from assembled instructions, never from
# .word (fixture-verified), and re-emitting decoded mnemonics would break byte
# fidelity. So code/data structure lives in the JSON manifest below, not the .dis.
dis_file="$DIS_DIR/dumped.dis"
dis2000 --data_as_text --all "$out_file" >"$dis_file"
echo "  $dis_file  ($(wc -l <"$dis_file") lines, $(stat -c%s "$dis_file") bytes)"

echo
echo "=== byte-fidelity check (derived COFF vs raw dump) ==="
# flash.bin is the immutable device extraction; the derived dumped.out MUST hold
# byte-identical region bytes or the .dis/CRC tooling is untrustworthy. A
# mismatch is fatal; a missing interpreter only skips the check.
if command -v "$PYTHON" >/dev/null 2>&1 && [[ -f $VERIFY_PY ]]; then
  if "$PYTHON" "$VERIFY_PY" "$DUMP_DIR"; then
    :
  else
    echo "error: reconstructed COFF is NOT byte-identical to the dump" >&2
    exit 1
  fi
else
  echo "  (skipped: no '$PYTHON' on PATH or verify_roundtrip.py missing)"
fi

echo
echo "=== classification manifest (code/data + function entries) ==="
# Standalone recursive-descent classifier (reuses the tms320c28x-re c28x decoder).
# Emits dumped.analysis.json -- the contract consumed by the BN dis_sidecar. This
# is best-effort: if python3/c28x/PyYAML are unavailable it is skipped without
# failing the reconstruction. Set C28X_RE_ROOT to the tms320c28x-re checkout if
# the c28x import fails.
analysis_file="$DIS_DIR/dumped.analysis.json"
if command -v "$PYTHON" >/dev/null 2>&1 && [[ -f $CLASSIFY_PY ]]; then
  if "$PYTHON" "$CLASSIFY_PY" "$DUMP_DIR" --out "$analysis_file"; then
    echo "  $analysis_file  ($(stat -c%s "$analysis_file") bytes)"
  else
    echo "  (classification unavailable -- manifest not written; pipeline continues)" >&2
    echo "   hint: set C28X_RE_ROOT to your tms320c28x-re checkout (needs c28x/ + isa/)" >&2
  fi
else
  echo "  (skipped: no '$PYTHON' on PATH or classify_f28335.py missing)"
fi

echo
echo "=== summary ==="
echo "  regions encoded:  ${#asm_inputs[@]}"
echo "  regions skipped:  ${#missing[@]}${missing[*]:+ (${missing[*]})}"
echo "  log:              $LOG"
echo "done: $(date -Iseconds)"
