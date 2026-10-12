# The real install on the OMEN's internal NVMe, alongside Windows and Arch.
# Partition layout and install steps: ../../INSTALL.md
#
#   p1  512M vfat   shared ESP (Windows Boot Manager + systemd-boot)  -> /efi
#   p5    1G vfat   XBOOTLDR (Arch + NixOS kernels/initrds)           -> /boot
#   p6   32G swap   shared with Arch (never mkswap: Arch's fstab uses its UUID)
#   p7  450G ext4   Arch /
#   p8 ~200G ext4   NixOS /
#
# hardware-configuration.nix comes from /etc/nixos/ after the bootstrap install.
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "QUINN-OMEN";

  my.nvidia.enable = true;
  my.lerd.enable = true;

  # Same bootloader setup as ../../bootstrap/configuration.nix; keep them in sync
  # until the bootstrap config is no longer needed.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    systemd-boot = {
      enable = true;
      xbootldrMountPoint = "/boot";
      configurationLimit = 5; # the 1G XBOOTLDR also holds Arch's ~250M kernel set
      # Windows Boot Manager on the ESP is detected automatically ("auto-windows").
      # Arch's kernel stays where mkinitcpio writes it (root of p5); options copied
      # from Arch's /proc/cmdline.
      extraEntries."arch.conf" = ''
        title   Arch Linux
        linux   /vmlinuz-linux
        initrd  /initramfs-linux.img
        options root=UUID=a995aed1-e84b-4fb6-bcde-e3752e2a9674 rw loglevel=3 quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1
      '';
    };
    timeout = 3; # hold Space for the menu if this is ever set to 0
  };

  hardware.cpu.intel.updateMicrocode = true;
}
