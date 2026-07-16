# Disk layout for a nixos-anywhere install. disko owns partitioning AND
# generates the fileSystems.* entries, so hardware.nix carries none.
# ⚠️  Confirm the device path on the target (`lsblk`) before installing —
# nixos-anywhere WIPES this disk. /dev/nvme0n1 is the usual single-NVMe path.
{
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
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
}
