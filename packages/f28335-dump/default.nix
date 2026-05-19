# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Dumps Flash, RAM, Boot ROM, OTP, and peripheral frames from a TMS320F28335
# via TI UniFlash's dslite CLI over an XDS200 USB JTAG probe.
{
  lib,
  writeShellApplication,
  uniflash,
  coreutils,
  procps,
}:
let
  defaultCcxml = ./f28335_xds200.ccxml;
  script = builtins.replaceStrings [ "@default_ccxml@" ] [ "${defaultCcxml}" ] (
    builtins.readFile ./dump_f28335.sh
  );
in
writeShellApplication {
  name = "dump_f28335";

  runtimeInputs = [
    uniflash
    coreutils
    procps
  ];

  text = script;

  meta = {
    description = "Dump TMS320F28335 Flash/RAM/OTP/Boot-ROM via UniFlash + XDS200";
    homepage = "https://www.ti.com/product/TMS320F28335";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "dump_f28335";
  };
}
