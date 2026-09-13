# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Reverse engineering / binary analysis. Entered with `dev reverse-engineering`.
#
{ inputs, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (inputs.seclab-pkgs.lib) toolsets;

      # pwntools ships a bin/checksec too, and buildEnv refuses the collision.
      binary-analysis = lib.remove pkgs.checksec (toolsets.binary-analysis { inherit pkgs; });
    in
    {
      devshells.reverse-engineering = {
        devshell = {
          name = "reverse-engineering";
          meta.description = "Binary analysis: ghidra+ReVa, angr, rizin, gdb+pwndbg, frida, pwntools";
          packages =
            binary-analysis
            ++ toolsets.reversing { inherit pkgs; }
            ++ toolsets.debugging { inherit pkgs; }
            ++ toolsets.python { inherit pkgs; }
            ++ [
              # keep-sorted start
              pkgs.binutils
              pkgs.binwalk
              pkgs.file
              pkgs.hexyl
              pkgs.mcp-reva
              pkgs.patchelf
              pkgs.scanmem
              pkgs.unixtools.xxd
              #pkgs.unblob
              pkgs.upx
              pkgs.volatility3
              pkgs.yara
              # keep-sorted end
            ];
        };

        env = [
          # mcp-reva and pyghidra locate Ghidra through these two.
          {
            name = "GHIDRA_INSTALL_DIR";
            value = "${pkgs.ghidra-re}/lib/ghidra";
          }
          {
            name = "JAVA_HOME";
            value = pkgs.openjdk21.home;
          }
          # libtriton installs outside the python env.
          {
            name = "PYTHONPATH";
            prefix = "${pkgs.libtriton}/${pkgs.python3.sitePackages}";
          }
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isx86_64 {
          name = "DynamoRIO_DIR";
          value = "${pkgs.dynamorio}/cmake";
        };
      };
    };
}
