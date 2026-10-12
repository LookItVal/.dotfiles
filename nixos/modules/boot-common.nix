# Bootloader settings live in the hosts themselves (USB: removable GRUB,
# internal: systemd-boot + XBOOTLDR). This file only holds kernel/initrd
# settings that are the same for both.
{ lib, ... }:
{
  # Mirrors the Arch cmdline `quiet loglevel=3`
  boot.kernelParams = [ "quiet" "loglevel=3" ];
  boot.consoleLogLevel = lib.mkDefault 3;

  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g (Windows partitions)
}
