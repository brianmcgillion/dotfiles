# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Example to create a bios compatible gpt partition
{
  disko.devices = {
    #Primary disk
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.36344830545091330025384a00000001";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            # Enable efi for boot
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
      #Second disk for mainly data
      data = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.36344830545091260025384a00000001";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data";
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
