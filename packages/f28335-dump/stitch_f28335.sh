#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Stitch the per-region .bin files in a dump directory into a single 8 MiB
# raw byte image of the F28335 chip address space. Each region's bytes are
# placed at file offset = chip_addr * 2 (Binary Ninja's C28x plugin
# convention: BN_byte = 2 * chip_word). Gaps are filled with 0xFF.
#
# The resulting file is loadable in Binary Ninja the same way flash.bin is
# loaded today, just with base address 0 instead of 0x600000. Cross-region
# xrefs (flash -> SARAM ramfuncs, flash -> M0 stubs, flash -> bootrom) all
# resolve inside one binary view.
#
# Usage:
#   stitch_f28335 <dump-dir>

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: stitch_f28335 <dump-dir>" >&2
  exit 2
fi

DUMP_DIR=$(realpath "$1")
if [[ ! -d $DUMP_DIR ]]; then
  echo "error: not a directory: $DUMP_DIR" >&2
  exit 1
fi

OUT="$DUMP_DIR/chip_image.bin"
CHIP_BYTES=$((0x800000)) # 4 M words = 8 MiB

# region table: bin filename | chip-word origin
# Mirrors dump_f28335.sh's region list; names follow TI canonical terminology
# (SPRS439 datasheet, SPRUFB0 peripheral reference).
# - flash.bin is resolved with a glob to match renamed variants
#   (g103-flash.bin, g104-flash.bin, etc.)
# - csm_pwl is included even though it overlaps .flash: it writes the
#   same 16 bytes that flash.bin already carries at chip 0x33FFF8.
regions=(
  "m0_saram.bin     0x000000"
  "m1_saram.bin     0x000400"
  "pf0.bin          0x000800"
  "pf3.bin          0x005000"
  "pf1.bin          0x006000"
  "pf2.bin          0x007000"
  "saram_l0.bin     0x008000"
  "saram_l1.bin     0x009000"
  "saram_l2.bin     0x00a000"
  "saram_l3.bin     0x00b000"
  "saram_l4.bin     0x00c000"
  "saram_l5.bin     0x00d000"
  "saram_l6.bin     0x00e000"
  "saram_l7.bin     0x00f000"
  "flash.bin        0x300000"
  "csm_pwl.bin      0x33FFF8"
  "adc_cal.bin      0x380080"
  "partid.bin       0x380090"
  "user_otp.bin     0x380400"
  "saram_l0_pgm.bin 0x3f8000"
  "saram_l1_pgm.bin 0x3f9000"
  "saram_l2_pgm.bin 0x3fa000"
  "saram_l3_pgm.bin 0x3fb000"
  "bootrom.bin      0x3fe000"
)

echo "stitch_f28335: $DUMP_DIR"
echo "output:        $OUT"

# Step 1: create 8 MiB file pre-filled with 0xFF (matches erased flash).
# Subshell with pipefail disabled because head closes the pipe early; tr
# then exits with SIGPIPE (141), which is expected and harmless here.
(
  set +o pipefail
  </dev/zero tr '\0' '\377' | head -c "$CHIP_BYTES" >"$OUT"
)

# Step 2: splice each region in place at byte offset = chip_addr * 2.
spliced=0
skipped=()
for row in "${regions[@]}"; do
  read -r fname chip <<<"$row"

  # The flash dump is renamed per variant (g103-flash.bin etc) when the
  # operator commits a capture. Resolve the first matching file.
  if [[ $fname == "flash.bin" && ! -f "$DUMP_DIR/$fname" ]]; then
    resolved=$(find "$DUMP_DIR" -maxdepth 1 -name '*flash*.bin' \
      ! -name 'flash_*' -type f -printf '%f\n' 2>/dev/null |
      head -n1)
    if [[ -n $resolved ]]; then
      fname="$resolved"
    fi
  fi

  if [[ -z $fname || ! -f "$DUMP_DIR/$fname" ]]; then
    skipped+=("$fname")
    continue
  fi

  off=$((chip * 2))
  sz=$(stat -c%s "$DUMP_DIR/$fname")
  printf '  %-22s chip 0x%06x -> byte 0x%06x  (%d B)\n' \
    "$fname" "$chip" "$off" "$sz"
  dd if="$DUMP_DIR/$fname" of="$OUT" \
    bs=1 seek="$off" conv=notrunc status=none
  spliced=$((spliced + 1))
done

if ((spliced == 0)); then
  echo "error: no region .bin files found under $DUMP_DIR" >&2
  exit 1
fi

actual_size=$(stat -c%s "$OUT")
sha=$(sha256sum "$OUT" | cut -d' ' -f1)
echo
echo "spliced regions: $spliced"
if ((${#skipped[@]} > 0)); then
  echo "skipped (not in dump-dir): ${skipped[*]}"
fi
echo "file size:       $actual_size bytes ($CHIP_BYTES expected)"
echo "sha256:          $sha"

if ((actual_size != CHIP_BYTES)); then
  echo "error: output file size mismatch" >&2
  exit 1
fi
