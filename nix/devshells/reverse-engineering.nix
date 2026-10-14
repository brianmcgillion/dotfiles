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

      # pwntools ships a bin/checksec and pulls in ropgadget, so the python env
      # provides both bins too and buildEnv refuses the collision.
      binary-analysis = lib.subtractLists [ pkgs.checksec pkgs.ropgadget ] (
        toolsets.binary-analysis { inherit pkgs; }
      );

      # rizin and cutter each wrap their own rz-ghidra build, so their copies of
      # lib/rizin/plugins and rz_ghidra.pc differ and buildEnv refuses the collision.
      # Both tools load plugins through their own NIX_RZ_PREFIX, so which copy wins
      # in the merged tree does not matter.
      cutter = pkgs.cutter.withPlugins (ps: [ ps.rz-ghidra ]);
      reversing = lib.remove cutter (toolsets.reversing { inherit pkgs; }) ++ [ (lib.lowPrio cutter) ];
    in
    {
      devshells.reverse-engineering = {
        devshell = {
          name = "reverse-engineering";
          meta.description = "Binary analysis: ghidra+ReVa, angr, rizin, gdb+pwndbg, frida, pwntools";
          # For a disk image, reach for qemu-nbd plus sleuthkit before mounting
          # anything: `qemu-nbd -r -c /dev/nbd0 image.vdi` exposes any format qemu
          # knows as a read-only block device, and sleuthkit (fls, icat) walks and
          # extracts from NTFS by inode without a filesystem mount at all.
          packages =
            binary-analysis
            ++ reversing
            ++ toolsets.debugging { inherit pkgs; }
            ++ toolsets.forensics { inherit pkgs; }
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
