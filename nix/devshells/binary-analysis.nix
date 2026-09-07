# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Packages specifically for binary analysis and triage.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.binary-analysis = {
        devshell = {
          name = "binary-analysis";
          meta.description = "Binary analysis training: static glibc, checksec, binutils, strace/ltrace";
          packages = [
            # keep-sorted start
            pkgs.binutils
            pkgs.checksec
            pkgs.file
            pkgs.glibc.static
            pkgs.ltrace
            pkgs.patchelf
            pkgs.strace
            pkgs.unixtools.xxd
            # keep-sorted end
          ];
        };

        env = [
          # Plain path, not a linker flag: see the header comment for why
          # this is not NIX_LDFLAGS. Consumed only by binary-practice's
          # Makefile, on its `%.static` pattern rule.
          {
            name = "GLIBC_STATIC_LIB";
            value = "${pkgs.glibc.static}/lib";
          }
        ];
      };
    };
}
