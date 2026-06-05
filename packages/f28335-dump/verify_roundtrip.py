#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
"""verify_roundtrip -- byte-fidelity check for an F28335 reconstruction.

``flash.bin`` is the raw JTAG device extraction -- the immutable ground truth;
it is never rebuilt. What ``reconstruct_f28335`` *derives* is ``link/dumped.out``
(a COFF) and ``dis/dumped.dis``. CRC tooling and the disassembly are only
trustworthy if the derived COFF contains byte-identical region bytes.

This check extracts each file-backed region's bytes from ``dumped.out`` and
compares them to the original ``<region>.bin``. Any difference -- including the
``.align``/padding/reorder that a careless code/data section split could
introduce -- fails the check (non-zero exit).

It is deliberately self-contained: it parses just enough TI COFF2 to read a
named section's raw bytes, with no dependency on the c28x decoder package, so
the fidelity gate stands on its own.

Usage:
    verify_roundtrip <dump-dir> [--coff PATH] [--quiet]

Exit status: 0 = all checked regions byte-identical; 1 = mismatch / error.
"""

from __future__ import annotations

import argparse
import hashlib
import struct
import sys
from pathlib import Path

COFF_MAGIC_C2000 = 0x00C2

# (region .bin filename, COFF section name). Mirrors reconstruct_f28335.sh.
# flash.bin is resolved leniently (renamed variants) like the reconstruct script.
REGION_SECTIONS = [
    ("flash.bin", ".flash"),
    ("bootrom.bin", ".bootrom"),
    ("m0_saram.bin", ".m0_saram"),
    ("m1_saram.bin", ".m1_saram"),
    ("pf0.bin", ".pf0"),
    ("pf1.bin", ".pf1"),
    ("pf2.bin", ".pf2"),
    ("pf3.bin", ".pf3"),
    ("saram_l0.bin", ".saram_l0"),
    ("saram_l1.bin", ".saram_l1"),
    ("saram_l2.bin", ".saram_l2"),
    ("saram_l3.bin", ".saram_l3"),
    ("saram_l4.bin", ".saram_l4"),
    ("saram_l5.bin", ".saram_l5"),
    ("saram_l6.bin", ".saram_l6"),
    ("saram_l7.bin", ".saram_l7"),
    ("saram_l0_pgm.bin", ".saram_l0_pgm"),
    ("saram_l1_pgm.bin", ".saram_l1_pgm"),
    ("saram_l2_pgm.bin", ".saram_l2_pgm"),
    ("saram_l3_pgm.bin", ".saram_l3_pgm"),
    ("adc_cal.bin", ".adc_cal"),
    ("partid.bin", ".partid"),
    ("user_otp.bin", ".user_otp"),
]


def read_coff_sections(path: Path) -> dict[str, bytes]:
    """Return {section_name: raw_bytes} for every section in a TI COFF2 file.

    A section's byte length is ``size_words * 2`` (C28x is word-addressed; each
    word is 2 file bytes). Sub-sections of a region concatenate in the same
    section name, so this also catches a code/data split that perturbs bytes.
    """
    data = path.read_bytes()
    magic = struct.unpack_from("<H", data, 0)[0]
    if magic != COFF_MAGIC_C2000:
        raise ValueError(f"{path}: not a TI C2000 COFF (magic=0x{magic:04X})")

    num_sections = struct.unpack_from("<H", data, 2)[0]
    symtab_offset = struct.unpack_from("<I", data, 8)[0]
    num_symbols = struct.unpack_from("<I", data, 12)[0]
    opt_hdr_size = struct.unpack_from("<H", data, 16)[0]
    hdr_size = 22 + opt_hdr_size
    strtab = symtab_offset + num_symbols * 18

    out: dict[str, bytes] = {}
    for i in range(num_sections):
        sh = hdr_size + i * 48
        raw_name = data[sh:sh + 8]
        if raw_name[:4] == b"\x00\x00\x00\x00":
            str_off = struct.unpack_from("<I", raw_name, 4)[0]
            end = data.index(b"\x00", strtab + str_off)
            name = data[strtab + str_off:end].decode("ascii", "replace")
        else:
            name = raw_name.rstrip(b"\x00").decode("ascii", "replace")
        size_words = struct.unpack_from("<I", data, sh + 16)[0]
        data_ptr = struct.unpack_from("<I", data, sh + 20)[0]
        flags = struct.unpack_from("<I", data, sh + 40)[0]
        byte_size = size_words * 2
        STYP_BSS = 0x0080
        sec = b""
        if data_ptr > 0 and size_words > 0 and not (flags & STYP_BSS):
            sec = data[data_ptr:data_ptr + byte_size]
        # Concatenate if a name repeats (split sub-sections).
        out[name] = out.get(name, b"") + sec
    return out


def resolve_flash(dump_dir: Path) -> Path | None:
    default = dump_dir / "flash.bin"
    if default.is_file():
        return default
    for p in sorted(dump_dir.glob("*flash*.bin")):
        if not p.name.startswith("flash_"):
            return p
    return None


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="verify_roundtrip",
        description="Check that reconstruct's COFF is byte-identical to the dump.",
    )
    ap.add_argument("dump_dir")
    ap.add_argument("--coff", help="COFF path (default <dump-dir>/link/dumped.out)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args(argv)

    dump_dir = Path(args.dump_dir).resolve()
    coff_path = Path(args.coff) if args.coff else dump_dir / "link" / "dumped.out"
    if not coff_path.is_file():
        sys.stderr.write(f"verify_roundtrip: no COFF at {coff_path}\n")
        return 1

    try:
        sections = read_coff_sections(coff_path)
    except Exception as e:  # malformed COFF -> fail the gate, don't mask it
        sys.stderr.write(f"verify_roundtrip: {e}\n")
        return 1

    def log(msg: str) -> None:
        if not args.quiet:
            print(msg)

    log(f"verify_roundtrip: {dump_dir}")
    checked = ok = 0
    failures: list[str] = []
    for bin_name, sec_name in REGION_SECTIONS:
        bin_path = resolve_flash(dump_dir) if bin_name == "flash.bin" \
            else dump_dir / bin_name
        if bin_path is None or not bin_path.is_file():
            continue
        if sec_name not in sections:
            log(f"  {bin_name:18s} -> {sec_name}: SECTION MISSING in COFF")
            failures.append(f"{sec_name} missing")
            continue
        want = bin_path.read_bytes()
        got = sections[sec_name]
        checked += 1
        if got == want:
            ok += 1
            log(f"  {bin_name:18s} == {sec_name:14s} OK  ({len(want)} bytes, "
                f"sha256 {hashlib.sha256(want).hexdigest()[:16]})")
        else:
            first = next((i for i in range(min(len(want), len(got)))
                          if want[i] != got[i]), min(len(want), len(got)))
            msg = (f"{sec_name}: MISMATCH (bin={len(want)}B coff={len(got)}B, "
                   f"first diff @0x{first:X})")
            log(f"  {bin_name:18s} != {sec_name:14s} {msg}")
            failures.append(msg)

    log(f"verify_roundtrip: {ok}/{checked} regions byte-identical")
    if failures:
        sys.stderr.write("verify_roundtrip: FAIL\n  " + "\n  ".join(failures) + "\n")
        return 1
    if checked == 0:
        sys.stderr.write("verify_roundtrip: no regions checked (missing .bin files?)\n")
        return 1
    log("verify_roundtrip: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
