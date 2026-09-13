# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Reverse engineering / binary analysis. Entered with `dev reverse-engineering`.
#
# Binary Ninja is deliberately absent: it is an out-of-tree requireFile vendor
# zip owned by seclab-pkgs' homeModules.binaryninja and gated on
# features.development.binaryninja.enable, so pulling it in here would break
# this shell on every host that does not have the zip staged.
#
# unblob is absent for a different reason: nixpkgs cannot build it right now.
# Its python fs dependency (via pyfatfs) is marked broken since setuptools 83
# dropped pkg_resources, and partclone no longer compiles against nilfs-utils
# 2.3.1. binwalk covers the same ground until both land upstream.
#
{
  perSystem =
    { pkgs, ... }:
    let
      # Every Python-based tool goes through this one interpreter rather than
      # being listed as a separate top-level package. devshell composes
      # `packages` with pkgs.buildEnv, which refuses conflicting subpaths, and
      # pwntools already propagates ROPGadget - so `pkgs.ropgadget` alongside
      # this env collides on bin/.ROPgadget-wrapped. One env, no collisions,
      # and `python` in the shell can import all of them.
      #
      # TODO: FIX: Pinned to python313 rather than pkgs.python3 (3.14): angr and its suite
      # are only packaged for 3.13, and two interpreters in one buildEnv
      # collide on bin/idle3.
      pythonEnv = pkgs.python313.withPackages (
        ps: with ps; [
          # keep-sorted start
          angr
          capstone
          frida-python
          pwntools
          pyelftools
          ropgadget
          ropper
          unicorn
          z3-solver
          # keep-sorted end
        ]
      );
    in
    {
      devshells.reverse-engineering = {
        devshell = {
          name = "reverse-engineering";
          meta.description = "Binary analysis: ghidra+ReVa, angr, rizin, gdb+gef, lldb, frida, pwntools";
          packages = [
            # keep-sorted start
            pkgs.binutils
            pkgs.binwalk
            pkgs.cutter
            pkgs.file
            pkgs.frida-tools
            pkgs.gdb
            pkgs.gef
            pkgs.ghidra-re
            pkgs.hexyl
            pkgs.lldb
            pkgs.ltrace
            pkgs.mcp-reva
            pkgs.patchelf
            pkgs.qemu
            pkgs.radare2
            pkgs.rizin
            pkgs.scanmem
            pkgs.strace
            #pkgs.unblob
            pkgs.unixtools.xxd
            pkgs.upx
            pkgs.valgrind
            pkgs.volatility3
            pkgs.yara
            pkgs.z3
            # keep-sorted end
            pythonEnv
          ];
        };
      };
    };
}
