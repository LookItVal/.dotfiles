# Bootstrap config for the first NixOS install on QUINN-OMEN (see ../INSTALL.md).
#
# Deliberately minimal: console only, no desktop, no NVIDIA driver. Its only jobs are
# to boot NixOS, keep Arch and Windows bootable, and get you online so the real flake
# (../flake.nix) can be built from inside NixOS.
#
# On install day:
#   curl -L https://raw.githubusercontent.com/LookItVal/.dotfiles/main/nixos/bootstrap/configuration.nix \
#     -o /mnt/etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # systemd-boot lives on the ESP shared with Windows (p1, /efi).
  # Kernels/initrds live on the XBOOTLDR partition (p5, /boot), shared with Arch.
  # Windows Boot Manager on the ESP is detected automatically ("auto-windows").
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    systemd-boot = {
      enable = true;
      xbootldrMountPoint = "/boot";
      configurationLimit = 5;
      # Arch's kernel stays where mkinitcpio already writes it (root of p5).
      # Options are copied from Arch's current /proc/cmdline.
      extraEntries."arch.conf" = ''
        title   Arch Linux
        linux   /vmlinuz-linux
        initrd  /initramfs-linux.img
        options root=UUID=a995aed1-e84b-4fb6-bcde-e3752e2a9674 rw loglevel=3 quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1
      '';
    };
    timeout = 3;
  };

  # The console runs on the Intel iGPU. Keep nouveau off the RTX 5070 until the
  # flake brings in the proper NVIDIA driver.
  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  networking.hostName = "QUINN-OMEN";
  networking.networkmanager.enable = true; # `nmtui` to join Wi-Fi after first boot

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.val = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  environment.systemPackages = with pkgs; [ git vim curl efibootmgr ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Matches the 26.05 installer. Never change this after install.
  system.stateVersion = "26.05";
}
