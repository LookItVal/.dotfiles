# The real install on the OMEN's internal NVMe (currently: Windows + Arch).
# Don't deploy this until hardware-configuration.nix is the real, generated one
# and the TODOs below are decided. See ../../README.md ("Porting to the internal drive").
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "QUINN-OMEN";

  my.nvidia.enable = true;

  # Same bootloader family as the Arch install (GRUB + os-prober so Windows shows up).
  # Decide where the ESP is first -- see TODO.md. Installing GRUB into the ESP Arch
  # uses will take over its boot entry.
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      default = "saved"; # required for `grub-reboot` (the reboot-windows alias in zshrc)
    };
    efi.canTouchEfiVariables = true;
  };

  hardware.cpu.intel.updateMicrocode = true;
}
