# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Bare-metal ARM cross toolchain and flashing tools. Entered with
# `dev embedded`.
#
# Separate from ./c-cpp.nix: gcc-arm-embedded's arm-none-eabi-gdb collides
# with the host gdb on include/gdb/jit-reader.h under pkgs.buildEnv.
#
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.embedded = {
        devshell = {
          name = "embedded";
          meta.description = "Embedded/hardware: arm-none-eabi, openocd, probe-rs, flashrom, sigrok";
          packages = inputs.seclab-pkgs.lib.toolsets.hardware { inherit pkgs; } ++ [
            # keep-sorted start
            pkgs.cmake
            pkgs.gcc-arm-embedded
            pkgs.ninja
            # keep-sorted end
          ];
        };
      };
    };
}
