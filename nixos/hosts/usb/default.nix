# Portable NixOS-on-a-stick. Goals: boot on whatever UEFI machine it's plugged
# into, and not wear out the flash. Intended first target is the OMEN laptop itself.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./disko.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking.hostName = "nixusb";
  my.lean = true; # 29 GB test stick: skip the heavy GUI apps (see modules/lean.nix)

  # The OMEN-specific graphics stack. A second boot entry ("no-nvidia") below
  # turns it off for other machines.
  my.nvidia.enable = true;
  specialisation.no-nvidia.configuration = {
    my.nvidia.enable = lib.mkForce false;
  };

  # --- boot: removable-media style EFI install (no NVRAM writes) -------------
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true; # -> \EFI\BOOT\BOOTX64.EFI on the stick's ESP
      device = "nodev";
    };
    efi.canTouchEfiVariables = false;
    timeout = 3;
  };

  # --- portability: broad initrd so root can be found on many machines -------
  boot.initrd.availableKernelModules = [
    # USB
    "xhci_pci" "xhci_hcd" "ehci_pci" "usb_storage" "uas" "usbhid" "sd_mod"
    # SATA / NVMe / card readers, in case the stick is cloned to an internal disk
    "ahci" "nvme" "sdhci_pci" "rtsx_pci_sdmmc" "vmd"
    "thunderbolt"
  ];
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- be kind to flash --------------------------------------------------------
  zramSwap.enable = true;                          # swap in RAM, no swap partition
  boot.tmp.useTmpfs = true;
  services.journald.settings.Journal = {
    Storage = "volatile";
    RuntimeMaxUse = "64M";
  };
}
