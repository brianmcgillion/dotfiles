# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# TI C2000 Code Generation Tools (CGT) - compiler/linker/archiver/disassembler
# for C28x and CLA targets (TMS320F28xxx DSP family).
#
# Provides cl2000 (compiler), lnk2000 (linker), ar2000 (archiver) and, when
# packaged, dis2000 (disassembler). Used for firmware audit / reverse
# engineering of TMS320F28335 binaries.
#
# Usage:
#   features.development.c2000-cgt.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.c2000-cgt;
in
{
  options.features.development.c2000-cgt = {
    enable = lib.mkEnableOption "TI C2000 code generation toolchain (cl2000, lnk2000, ar2000)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.c2000-cgt
    ];
  };
}
