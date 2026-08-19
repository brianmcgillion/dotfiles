# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Bare-metal ARM cross toolchain and flashing tools. Entered with
# `dev embedded`.
#
# Separate from ./c-cpp.nix on purpose: gcc-arm-embedded ships its own
# arm-none-eabi-gdb whose include/gdb/jit-reader.h collides with the host gdb
# under pkgs.buildEnv. Keeping them apart also means a host C build does not
# drag in a cross compiler.
#
# Host-side embedded helpers that are always wanted (proploader, socat) stay in
# home/development/embedded.nix.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.embedded = {
        devshell = {
          name = "embedded";
          meta.description = "Bare-metal ARM: arm-none-eabi, openocd, probe-rs, dfu-util";
          packages = [
            # keep-sorted start
            pkgs.cmake
            pkgs.dfu-util
            pkgs.gcc-arm-embedded
            pkgs.minicom
            pkgs.ninja
            pkgs.openocd
            pkgs.picocom
            pkgs.probe-rs-tools
            pkgs.stlink
            # keep-sorted end
          ];
        };
      };
    };
}
