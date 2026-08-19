# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Reverse engineering / binary analysis. Entered with `dev reverse-engineering`.
#
# Binary Ninja is deliberately absent: it is an out-of-tree requireFile vendor
# zip owned by home/development/binary-ninja.nix and gated on
# features.development.binaryninja.enable, so pulling it in here would break
# this shell on every host that does not have the zip staged.
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
      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
          # keep-sorted start
          capstone
          pwntools
          pyelftools
          ropgadget
          ropper
          unicorn
          # keep-sorted end
        ]
      );
    in
    {
      devshells.reverse-engineering = {
        devshell = {
          name = "reverse-engineering";
          meta.description = "Binary analysis: ghidra, rizin, gdb+gef, pwntools";
          packages = [
            # keep-sorted start
            pkgs.binutils
            pkgs.binwalk
            pkgs.cutter
            pkgs.file
            pkgs.gdb
            pkgs.gef
            pkgs.ghidra
            pkgs.hexyl
            pkgs.ltrace
            pkgs.patchelf
            pkgs.qemu
            pkgs.radare2
            pkgs.rizin
            pkgs.strace
            pkgs.upx
            pkgs.valgrind
            pkgs.yara
            # keep-sorted end
            pythonEnv
          ];
        };
      };
    };
}
