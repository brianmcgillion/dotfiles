# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Example to create a bios compatible gpt partition
{
  disko.devices = {
    #Primary disk
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # MBR partition for GRUB
            boot = {
              size = "1M";
              type = "EF02";
            };
            # EFI System Partition
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "32G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
            # Assign everything to one root partition
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
    # A true tmpfs
    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [ "size=200M" ];
      };
    };
  };
}
