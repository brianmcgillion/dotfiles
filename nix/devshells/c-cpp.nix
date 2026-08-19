# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Host C/C++ toolchain. Entered with `dev c-cpp`.
#
# home/development/base-system.nix keeps only clang-tools (Doom's cc +lsp needs
# clangd in buffers with no .envrc), gcc and gnumake global as an ambient build
# fallback; bear, cmake and llvm live here instead, since nothing outside a
# C/C++ project used them.
#
# The bare-metal cross toolchain lives in ./embedded.nix, not here:
# gcc-arm-embedded and gdb both ship include/gdb/jit-reader.h, and devshell
# composes `packages` with pkgs.buildEnv, which refuses conflicting subpaths
# and exposes no ignoreCollisions escape hatch.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.c-cpp = {
        devshell = {
          name = "c-cpp";
          meta.description = "C/C++: clang, gdb/lldb, meson, valgrind, cppcheck";
          packages = [
            # keep-sorted start
            pkgs.bear
            pkgs.ccache
            pkgs.clang
            pkgs.clang-tools
            pkgs.cmake
            pkgs.cppcheck
            pkgs.gdb
            pkgs.include-what-you-use
            pkgs.lldb
            pkgs.llvm
            pkgs.meson
            pkgs.ninja
            pkgs.pkg-config
            pkgs.valgrind
            # keep-sorted end
          ];
        };

        env = [
          # Emit compile_commands.json by default so clangd works without
          # every project having to remember the flag.
          {
            name = "CMAKE_EXPORT_COMPILE_COMMANDS";
            value = "1";
          }
        ];
      };
    };
}
