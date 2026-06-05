# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Dumps Flash, RAM, Boot ROM, OTP, and peripheral frames from a TMS320F28335
# via TI UniFlash's dslite CLI over an XDS200 USB JTAG probe, then rebuilds
# the dump into a linkable COFF + disassembly (reconstruct) and a single
# 8 MiB chip-image suitable for Binary Ninja (stitch).
{
  lib,
  writeShellApplication,
  symlinkJoin,
  uniflash,
  coreutils,
  procps,
  c2000-cgt,
  findutils,
  gawk,
  python3,
}:
let
  defaultCcxml = ./f28335_xds200.ccxml;

  # Python helpers run as a post-link stage: classify_f28335.py emits the
  # code/data + function manifest (needs PyYAML, via the c28x decoder it reuses)
  # and verify_roundtrip.py enforces byte-fidelity of the derived COFF (stdlib
  # only). The classifier imports the c28x package from a tms320c28x-re checkout
  # located via $C28X_RE_ROOT (or its built-in default path).
  reconstructPython = python3.withPackages (ps: [ ps.pyyaml ]);

  reconstruct = writeShellApplication {
    name = "reconstruct_f28335";
    runtimeInputs = [
      c2000-cgt
      coreutils
      findutils
      gawk
      reconstructPython
    ];
    # Bake the nix-store paths of the helper scripts into the @placeholders@.
    text = builtins.replaceStrings
      [ "@classify_py@" "@verify_py@" ]
      [ "${./classify_f28335.py}" "${./verify_roundtrip.py}" ]
      (builtins.readFile ./reconstruct_f28335.sh);
  };

  stitch = writeShellApplication {
    name = "stitch_f28335";
    runtimeInputs = [
      coreutils
      findutils
    ];
    text = builtins.readFile ./stitch_f28335.sh;
  };

  dumpScript = builtins.replaceStrings [ "@default_ccxml@" ] [ "${defaultCcxml}" ] (
    builtins.readFile ./dump_f28335.sh
  );

  dump = writeShellApplication {
    name = "dump_f28335";
    runtimeInputs = [
      uniflash
      coreutils
      procps
      reconstruct
      stitch
    ];
    text = dumpScript;
  };
in
symlinkJoin {
  name = "f28335-dump";
  paths = [
    dump
    reconstruct
    stitch
  ];
  meta = {
    description = "Dump, reconstruct, and stitch TMS320F28335 Flash/RAM/OTP/Boot-ROM via UniFlash + XDS200";
    homepage = "https://www.ti.com/product/TMS320F28335";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "dump_f28335";
  };
}
