#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
"""classify_f28335 -- code/data + function-entry classifier for TMS320F28335 dumps.

Standalone recursive-descent classifier that reuses the ``c28x.decoder`` from the
``tms320c28x-re`` Binary Ninja plugin. It produces a machine-readable manifest
(``dumped.analysis.json``) describing function entries, code ranges, and data
ranges of the code-bearing regions (flash + boot ROM), in chip-WORD addresses.

The manifest is the *contract* consumed by the BN sidecar importer
(``binja/dis_sidecar.py``): it lets Binary Ninja seed the ~150 KB of
long-branch-dispatched code it never reaches on its own, and stop disassembling
const tables (e.g. the dead WGS84 block) as code -- all without re-loading a COFF.

Usage
-----
    classify_f28335 <dump-dir> [--out PATH] [--min-data-words N] [--quiet]

``<dump-dir>`` is the directory holding ``flash.bin`` (and optionally
``bootrom.bin``), typically the ``dump-reset/`` subtree of ``dump_f28335``
output. By default the manifest is written to ``<dump-dir>/dis/dumped.analysis.json``.

Addressing
----------
The C28x is word-addressed (each address holds a 16-bit word). The decoder works
in a byte space where ``byte = word * 2``; pass it ``addr = word * 2`` and read
its ``branch_target`` back as ``target_word * 2``. All addresses in the emitted
manifest are chip-WORD addresses (ints; hex shown in comments alongside).

c28x import path
----------------
This script imports the ``c28x`` package (decoder/types/util) from the
``tms320c28x-re`` plugin repo. It is located in this order:

  1. already importable (``import c28x`` succeeds);
  2. ``$C28X_RE_ROOT`` -- repo root that contains ``c28x/`` and ``isa/``;
  3. the ``_DEFAULT_C28X_RE_ROOT`` fallback below (edit for your checkout).

The plugin's ``isa/`` YAML directory must sit alongside ``c28x/`` (it does in the
repo; ``c28x.isa.ISA`` resolves it relative to the package). PyYAML is required
(the plugin devshell's ``.venv`` provides it).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path

# Default location of the tms320c28x-re checkout (contains c28x/ and isa/).
_DEFAULT_C28X_RE_ROOT = os.path.expanduser(
    "~/projects/code/github.com/brianmcgillion/tms320c28x-re"
)


def _ensure_c28x_importable() -> None:
    """Make the ``c28x`` package importable, per the resolution order in the
    module docstring. Raises SystemExit with a clear message if it cannot."""
    try:
        import c28x.decoder  # noqa: F401
        return
    except Exception:
        pass

    candidates = []
    env_root = os.environ.get("C28X_RE_ROOT")
    if env_root:
        candidates.append(env_root)
    candidates.append(_DEFAULT_C28X_RE_ROOT)

    for root in candidates:
        if root and (Path(root) / "c28x" / "decoder.py").is_file():
            sys.path.insert(0, root)
            try:
                import c28x.decoder  # noqa: F401
                return
            except Exception:
                continue

    sys.stderr.write(
        "classify_f28335: cannot import the 'c28x' package.\n"
        "  Set C28X_RE_ROOT to your tms320c28x-re checkout (the dir that\n"
        "  contains c28x/ and isa/), or run from its Nix devshell venv.\n"
        f"  Tried: {', '.join(c for c in candidates if c)}\n"
    )
    raise SystemExit(3)


_ensure_c28x_importable()

from c28x.decoder import Decoder  # noqa: E402
from c28x.types import BranchType  # noqa: E402


# ── Region table (code-bearing regions only) ────────────────────────────────
# Mirrors reconstruct_f28335.sh / dump_f28335.sh. (filename, section, origin_word,
# len_words). Boot ROM is the TI mask ROM (boot loader); flash is the firmware.
@dataclass
class Region:
    name: str          # logical/section name, e.g. "flash"
    origin: int        # origin word address
    length: int        # length in words
    data: bytes        # raw little-endian word stream
    path: str          # source .bin path


CODE_REGIONS = [
    # (bin-filename, section-name, origin-word, len-words)
    ("flash.bin", "flash", 0x300000, 0x40000),
    ("bootrom.bin", "bootrom", 0x3FE000, 0x02000),
]

# Flash entry vector: the boot ROM branches here for "boot to flash". Holds an
# LB to _c_int00. (NB: this is word 0x33FFF6, just below the CSM password words
# 0x33FFF8-0x33FFFF -- NOT the boot ROM reset vector 0x3FFFC0.)
FLASH_ENTRY_VECTOR_WORD = 0x33FFF6
# Boot ROM reset vector (32-bit pointer to InitBoot), within the bootrom image.
BOOTROM_RESET_VECTOR_WORD = 0x3FFFC0

# Values that, when they appear in a LONG run, are filler/erased, not data:
#   0xFFFF erased flash, 0x0000 zero-fill, 0x7625 ESTOP0 (cl2000 sector filler).
# A *short* run (e.g. a lone 0x0000 between floats in a param table) is NOT
# padding -- it is part of the surrounding data block and must be absorbed.
PADDING_VALUES = (0x0000, 0xFFFF, 0x7625)
# Min length (words) of a single-value run for it to count as padding/filler.
DEFAULT_MIN_PAD_WORDS = 6

# Minimum span (words) for an uncovered, non-padding run to be called data.
# Conservative on purpose: substantial const blocks (WGS84, string/param pools)
# get marked; small ambiguous gaps (literal pools, descent-missed snippets) are
# left UNCLASSIFIED so the importer never forces likely-code to data.
DEFAULT_MIN_DATA_WORDS = 8


@dataclass
class Classifier:
    regions: list[Region]
    min_data_words: int = DEFAULT_MIN_DATA_WORDS
    min_pad_words: int = DEFAULT_MIN_PAD_WORDS
    quiet: bool = False

    decoder: Decoder = field(default_factory=lambda: Decoder(objmode=1))
    covered: set[int] = field(default_factory=set)        # words that are code
    insn_starts: set[int] = field(default_factory=set)    # descent instruction heads
    func_sources: dict[int, str] = field(default_factory=dict)  # entry_word -> source

    # ── address helpers ──────────────────────────────────────────────────
    def region_of(self, word: int) -> Region | None:
        for r in self.regions:
            if r.origin <= word < r.origin + r.length:
                return r
        return None

    def fetch(self, word: int, nbytes: int = 4) -> bytes:
        """Read up to ``nbytes`` raw bytes starting at chip-word ``word``."""
        r = self.region_of(word)
        if r is None:
            return b""
        off = (word - r.origin) * 2
        return r.data[off:off + nbytes]

    def word_value(self, word: int) -> int | None:
        b = self.fetch(word, 2)
        if len(b) < 2:
            return None
        return b[0] | (b[1] << 8)

    def _log(self, msg: str) -> None:
        if not self.quiet:
            sys.stderr.write(msg + "\n")

    # ── seed discovery ───────────────────────────────────────────────────
    def linear_scan(self) -> tuple[set[int], set[int], set[int]]:
        """Self-synchronising linear decode over every code region.

        Returns (call_targets, branch_targets, lin_starts):
          - call_targets: LCR/LC/FFC/XCALL destinations (-> function entries)
          - branch_targets: LB/SB/B(F) destinations (-> descent seeds only)
          - lin_starts: word addresses where a decode succeeded (prologue filter)
        """
        call_targets: set[int] = set()
        branch_targets: set[int] = set()
        lin_starts: set[int] = set()
        dec = self.decoder

        for r in self.regions:
            origin, length = r.origin, r.length
            w = origin
            end = origin + length
            while w < end:
                data = self.fetch(w, 4)
                if len(data) < 2:
                    break
                insn = dec.decode(data, addr=w * 2)
                if insn is None:
                    w += 1
                    continue
                lin_starts.add(w)
                if insn.branch_target is not None:
                    tw = insn.branch_target // 2
                    if self.region_of(tw) is not None:
                        if insn.is_call:
                            call_targets.add(tw)
                        elif insn.branch_type in (
                            BranchType.UNCONDITIONAL,
                            BranchType.CONDITIONAL_TRUE,
                            BranchType.CONDITIONAL_FALSE,
                        ):
                            branch_targets.add(tw)
                w += insn.size // 2
        return call_targets, branch_targets, lin_starts

    def prologue_scan(self, lin_starts: set[int]) -> set[int]:
        """ADDB SP, #N prologues ``(op16 & 0xFF80) == 0xFE00`` that fall on a
        linear-scan instruction boundary (filters most data false positives)."""
        out: set[int] = set()
        for r in self.regions:
            for w in range(r.origin, r.origin + r.length):
                if w not in lin_starts:
                    continue
                v = self.word_value(w)
                if v is not None and (v & 0xFF80) == 0xFE00:
                    out.add(w)
        return out

    def pointer_table_scan(self) -> set[int]:
        """Find runs of >=4 consecutive 32-bit values that are valid code-region
        word addresses (ISR/callback/jump tables in .const). Ports
        flash.py::_find_functions_from_pointer_tables to word space."""
        out: set[int] = set()
        for r in self.regions:
            n = r.length
            i = 0
            while i + 8 <= n * 2 - 8:  # need room for >=4 dwords
                run_start = i
                run = 0
                scan = i
                while scan + 4 <= n * 2:
                    lo = r.data[scan] | (r.data[scan + 1] << 8)
                    hi = r.data[scan + 2] | (r.data[scan + 3] << 8)
                    raw = lo | (hi << 16)
                    word_addr = raw & 0x3FFFFF
                    if raw != word_addr:                 # high bits set -> not a ptr
                        break
                    if self.region_of(word_addr) is not None:
                        run += 1
                        scan += 4
                    else:
                        break
                if run >= 4:
                    for k in range(run):
                        off = run_start + k * 4
                        lo = r.data[off] | (r.data[off + 1] << 8)
                        hi = r.data[off + 2] | (r.data[off + 3] << 8)
                        out.add((lo | (hi << 16)) & 0x3FFFFF)
                    i = scan
                else:
                    i += 4
        return out

    # ── recursive descent ────────────────────────────────────────────────
    def descend(self, seeds: set[int]) -> None:
        """Walk instructions from each seed, recording covered words and queuing
        call/branch successors, until return/halt/invalid/region-edge."""
        dec = self.decoder
        work = list(seeds)
        while work:
            cur = work.pop()
            while True:
                if cur in self.insn_starts:      # already walked (this/earlier call)
                    break
                if self.region_of(cur) is None:
                    break
                if self.word_value(cur) == 0xFFFF:  # erased-flash filler (TI: ITRAP1),
                    break                            # never a real code start
                data = self.fetch(cur, 4)
                if len(data) < 2:
                    break
                insn = dec.decode(data, addr=cur * 2)
                if insn is None:
                    break
                self.insn_starts.add(cur)
                size_words = insn.size // 2
                for k in range(size_words):
                    self.covered.add(cur + k)

                if insn.name == "ESTOP0":          # emulation halt -> no_ret
                    break

                bt = insn.branch_type
                tw = insn.branch_target // 2 if insn.branch_target is not None else None
                tgt_ok = tw is not None and self.region_of(tw) is not None

                if bt == BranchType.RETURN:
                    break
                if bt == BranchType.CALL:
                    if tgt_ok:
                        self.func_sources.setdefault(tw, "call")
                        if tw not in self.insn_starts:
                            work.append(tw)
                    cur += size_words                 # call returns -> fall through
                    continue
                if bt == BranchType.UNCONDITIONAL:
                    if tgt_ok and tw not in self.insn_starts:
                        work.append(tw)
                    break                              # no fall-through
                if bt in (BranchType.CONDITIONAL_TRUE, BranchType.CONDITIONAL_FALSE):
                    if tgt_ok and tw not in self.insn_starts:
                        work.append(tw)
                    cur += size_words
                    continue
                # NONE / TRAP -> fall through
                cur += size_words

    # ── gap recovery ─────────────────────────────────────────────────────
    def known_call_sites(self, lo: int, hi: int, known_funcs: set[int]) -> list[int]:
        """Addresses in [lo, hi) where an LCR/call targets an already-known
        function, scanned PER WORD (alignment-independent) so inline code is
        found even when a leading const pool desyncs a linear decode. Float/
        string data does not call known functions, so const pools (WGS84) yield
        ~none -- the count cleanly separates code (many) from data (0-1)."""
        sites: list[int] = []
        for w in range(lo, hi):
            b = self.fetch(w, 4)
            if len(b) < 4:
                break
            insn = self.decoder.decode(b, addr=w * 2)
            if (insn is not None and insn.is_call and insn.branch_target is not None
                    and (insn.branch_target // 2) in known_funcs):
                sites.append(w)
        return sites

    def _block_start(self, c: int, lo: int, max_back: int = 96) -> int:
        """Earliest all-valid instruction boundary in [max(lo, c-max_back), c]
        whose forward decode lands exactly on ``c`` -- walks a code block back to
        its head so descent seeds at the start of the inline routine, not in the
        const pool that precedes it."""
        best = c
        earliest = max(lo, c - max_back)
        s = c - 1
        while s >= earliest:
            w = s
            ok = True
            while w < c:
                b = self.fetch(w, 4)
                if len(b) < 2:
                    ok = False
                    break
                insn = self.decoder.decode(b, addr=w * 2)
                if insn is None:
                    ok = False
                    break
                w += insn.size // 2
            if ok and w == c:
                best = s
            s -= 1
        return best

    def recover_gaps(self, max_rounds: int = 8, min_gap: int = 8,
                     min_calls: int = 2) -> None:
        """Recover descent-missed code (indirect / fall-through-reached routines,
        e.g. the inline attitude pipeline) without polluting data. An uncovered
        span is treated as code only if it makes >= ``min_calls`` calls to
        already-known functions -- strong evidence no const pool can fake. We
        backward-align from the first such call to the enclosing block head and
        re-seed descent there. Iterates to a fixpoint."""
        for rnd in range(max_rounds):
            known_funcs = set(self.func_sources)
            new_seeds: set[int] = set()
            for r in self.regions:
                w = r.origin
                end = r.origin + r.length
                while w < end:
                    if w in self.covered:
                        w += 1
                        continue
                    start = w
                    while w < end and w not in self.covered:
                        w += 1
                    if w - start < min_gap:
                        continue
                    calls = self.known_call_sites(start, w, known_funcs)
                    if len(calls) >= min_calls:
                        # Seed every call site's enclosing block head so a span
                        # holding several disjoint code blocks is covered in one
                        # pass (not one block per round).
                        for c in calls:
                            new_seeds.add(self._block_start(c, start))
            if not new_seeds:
                break
            before = len(self.covered)
            self.descend(new_seeds)
            gained = len(self.covered) - before
            self._log(f"  gap-recovery round {rnd + 1}: +{len(new_seeds)} seeds, "
                      f"+{gained} code words")
            if gained == 0:
                break

    # ── range extraction ─────────────────────────────────────────────────
    def function_end(self, entry: int) -> int:
        """End (exclusive) of the maximal contiguous covered run from ``entry``."""
        w = entry
        while w in self.covered:
            w += 1
        return w

    def code_ranges(self) -> list[dict]:
        out: list[dict] = []
        for r in self.regions:
            w = r.origin
            end = r.origin + r.length
            while w < end:
                if w in self.covered:
                    start = w
                    while w < end and w in self.covered:
                        w += 1
                    out.append({"start_word": start, "end_word": w,
                                "section": f".{r.name}"})
                else:
                    w += 1
        return out

    def padding_words(self) -> set[int]:
        """Words inside a maximal run (>= min_pad_words) of a single padding
        value (0xFFFF/0x0000/0x7625). Short runs are NOT padding -- a lone
        0x0000 between floats stays part of its data block."""
        pad: set[int] = set()
        pads = set(PADDING_VALUES)
        for r in self.regions:
            origin, end = r.origin, r.origin + r.length
            w = origin
            while w < end:
                v = self.word_value(w)
                if v in pads:
                    start = w
                    while w < end and self.word_value(w) == v:
                        w += 1
                    if w - start >= self.min_pad_words:
                        pad.update(range(start, w))
                else:
                    w += 1
        return pad

    def data_ranges(self, padding: set[int] | None = None,
                    known_funcs: set[int] | None = None,
                    min_calls_code: int = 2) -> list[dict]:
        """Maximal runs of words that are neither code (descent-covered) nor
        long-run padding, >= min_data_words. Short padding gaps are absorbed.
        Safety net: a candidate run that makes >= ``min_calls_code`` calls to
        known functions is inline code descent did not reach -- never emit it as
        data (leave it unclassified) so the importer cannot hide real code."""
        if padding is None:
            padding = self.padding_words()
        if known_funcs is None:
            known_funcs = set(self.func_sources)
        out: list[dict] = []
        for r in self.regions:
            w = r.origin
            end = r.origin + r.length
            while w < end:
                if (w not in self.covered) and (w not in padding):
                    start = w
                    while w < end and (w not in self.covered) and (w not in padding):
                        w += 1
                    if w - start < self.min_data_words:
                        continue
                    if len(self.known_call_sites(start, w, known_funcs)) >= min_calls_code:
                        continue   # inline code, not data
                    out.append({"start_word": start, "end_word": w,
                                "section": f".{r.name}_const", "type": "const"})
                else:
                    w += 1
        return out

    # ── driver ───────────────────────────────────────────────────────────
    def run(self) -> dict:
        # Seeds: reset vectors.
        reset_seeds: set[int] = set()
        if self.region_of(FLASH_ENTRY_VECTOR_WORD) is not None:
            insn = self.decoder.decode(
                self.fetch(FLASH_ENTRY_VECTOR_WORD, 4),
                addr=FLASH_ENTRY_VECTOR_WORD * 2,
            )
            if insn and insn.branch_target is not None:
                tw = insn.branch_target // 2
                if self.region_of(tw) is not None:
                    reset_seeds.add(tw)
                    self.func_sources.setdefault(tw, "reset")
        # Boot ROM reset vector is a raw 32-bit pointer (not a branch insn).
        if self.region_of(BOOTROM_RESET_VECTOR_WORD) is not None:
            b = self.fetch(BOOTROM_RESET_VECTOR_WORD, 4)
            if len(b) == 4:
                raw = (b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)) & 0x3FFFFF
                if self.region_of(raw) is not None:
                    reset_seeds.add(raw)
                    self.func_sources.setdefault(raw, "reset")

        self._log("classify_f28335: linear scan ...")
        call_targets, branch_targets, lin_starts = self.linear_scan()
        self._log(f"  call targets={len(call_targets)} branch targets={len(branch_targets)}"
                  f" lin starts={len(lin_starts)}")

        prologues = self.prologue_scan(lin_starts)
        ptr_table = self.pointer_table_scan()
        self._log(f"  prologues={len(prologues)} pointer-table entries={len(ptr_table)}")

        # Descend ONLY from reliable entries (reset / direct call targets /
        # validated pointer tables) and follow control flow from real decoded
        # code. Blind linear-scan *branch* targets are deliberately NOT seeded:
        # over data they are garbage (floats decode as bogus B/SB) and would
        # walk descent into const pools, mis-marking data as code. LB-dispatched
        # code is still reached -- its dispatching LB lives in real code we walk.
        for tw in call_targets:
            self.func_sources.setdefault(tw, "call")
        for tw in ptr_table:
            self.func_sources.setdefault(tw, "pie")

        descent_seeds = reset_seeds | call_targets | ptr_table
        self._log(f"classify_f28335: recursive descent from {len(descent_seeds)} seeds ...")
        self.descend(descent_seeds)
        self._log(f"  covered words={len(self.covered)}")

        # Recover descent-missed code (fall-through / indirectly-called routines)
        # via anchored gap recovery -- without dragging const data into code.
        self._log("classify_f28335: gap recovery ...")
        self.recover_gaps()
        self._log(f"  covered words after recovery={len(self.covered)}")

        # Prologues are a *labeling* refinement: promote an ADDB-SP head to a
        # function only where descent confirmed it as a real instruction start.
        for w in prologues:
            if w in self.insn_starts:
                self.func_sources.setdefault(w, "prologue")

        # Drop any entry descent never confirmed as a decoded instruction start
        # (e.g. a bogus call target into data) so every listed function is code.
        for entry in [e for e in self.func_sources if e not in self.insn_starts]:
            del self.func_sources[entry]

        functions = []
        for entry in sorted(self.func_sources):
            functions.append({
                "name": f"fn_{entry:06X}",
                "entry_word": entry,
                "end_word": self.function_end(entry),
                "source": self.func_sources[entry],
            })

        code = self.code_ranges()
        padding = self.padding_words()
        data = self.data_ranges(padding, set(self.func_sources))
        section_map = [
            {"name": f".{r.name}", "origin_word": r.origin,
             "len_word": r.length, "page": 0}
            for r in self.regions
        ]

        cov = len(self.covered)
        total = sum(r.length for r in self.regions)
        dwords = sum(r["end_word"] - r["start_word"] for r in data)
        pwords = len(padding - self.covered)   # padding ∩ code -> count as code
        self._log(
            f"classify_f28335: functions={len(functions)} "
            f"code_ranges={len(code)} data_ranges={len(data)}"
        )
        self._log(
            f"  code={cov} ({100.0*cov/total:.1f}%)  data={dwords} ({100.0*dwords/total:.1f}%)"
            f"  padding={pwords} ({100.0*pwords/total:.1f}%)"
            f"  unclassified={total - cov - dwords - pwords}"
        )

        flash = next((r for r in self.regions if r.name == "flash"), self.regions[0])
        return {
            "version": 1,
            "device": "F28335",
            "source": flash.path,
            "functions": functions,
            "code_ranges": code,
            "data_ranges": data,
            "section_map": section_map,
        }


def _resolve_flash(dump_dir: Path) -> Path | None:
    """flash.bin, or a <variant>-flash.bin (matching reconstruct_f28335.sh)."""
    default = dump_dir / "flash.bin"
    if default.is_file():
        return default
    for p in sorted(dump_dir.glob("*flash*.bin")):
        if not p.name.startswith("flash_"):
            return p
    return None


def load_regions(dump_dir: Path) -> list[Region]:
    regions: list[Region] = []
    for bin_name, section, origin, length in CODE_REGIONS:
        if bin_name == "flash.bin":
            path = _resolve_flash(dump_dir)
        else:
            path = dump_dir / bin_name
            if not path.is_file():
                path = None
        if path is None:
            continue
        data = path.read_bytes()
        # Trust the region length from the table; clamp data to it.
        regions.append(Region(name=section, origin=origin, length=length,
                              data=data[:length * 2], path=str(path)))
    return regions


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="classify_f28335",
        description="Classify code/data + function entries in an F28335 dump.",
    )
    ap.add_argument("dump_dir", help="dir holding flash.bin (dump-reset/ subtree)")
    ap.add_argument("--out", help="manifest output path "
                    "(default: <dump-dir>/dis/dumped.analysis.json)")
    ap.add_argument("--min-data-words", type=int, default=DEFAULT_MIN_DATA_WORDS,
                    help=f"min uncovered span to call data (default {DEFAULT_MIN_DATA_WORDS})")
    ap.add_argument("--min-pad-words", type=int, default=DEFAULT_MIN_PAD_WORDS,
                    help=f"min single-value run to call padding (default {DEFAULT_MIN_PAD_WORDS})")
    ap.add_argument("--quiet", action="store_true", help="suppress progress on stderr")
    args = ap.parse_args(argv)

    dump_dir = Path(args.dump_dir).resolve()
    if not dump_dir.is_dir():
        sys.stderr.write(f"classify_f28335: not a directory: {dump_dir}\n")
        return 1

    regions = load_regions(dump_dir)
    if not regions:
        sys.stderr.write(f"classify_f28335: no code-bearing .bin in {dump_dir}\n")
        return 1

    clf = Classifier(regions=regions, min_data_words=args.min_data_words,
                     min_pad_words=args.min_pad_words, quiet=args.quiet)
    manifest = clf.run()

    out_path = Path(args.out) if args.out else dump_dir / "dis" / "dumped.analysis.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(manifest, indent=2) + "\n")
    sys.stderr.write(f"classify_f28335: wrote {out_path}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
