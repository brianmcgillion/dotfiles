# Example to create a bios compatible gpt partition
{
  disko.devices = {
    #Primary disk
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
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
