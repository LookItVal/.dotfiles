# Partitioning for the USB stick (GPT: 1 GiB ESP + ext4 root).
#
# !!! `device` is a PLACEHOLDER and the whole device gets WIPED when you run disko.
# Use a stable path, never /dev/sdX:
#     ls -l /dev/disk/by-id/ | grep -i usb
#     lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINT      # confirm it's the stick
{ lib, ... }:
let
  usbDevice = "/dev/disk/by-id/usb-_USB_DISK_3.0_07190A3B8B2A8382-0:0";
in
{
  disko.devices.disk.usb = {
    type = "disk";
    device = usbDevice;
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
            extraArgs = [ "-n" "NIXBOOT" ]; # FAT label (mkfs.fat -n)
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
            extraArgs = [ "-L" "nixusb" ]; # ext4 label (mkfs.ext4 -L)
          };
        };
      };
    };
  };
}
