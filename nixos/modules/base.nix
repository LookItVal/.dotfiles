# Settings shared by every host: nix itself, locale, time, networking.
{ lib, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Chrome, Slack, Spotify, VS Code, Cursor, Claude Code, nvidia, unrar, ...
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Chicago"; # was US/Central on Arch
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.networkmanager.enable = true;
  services.tailscale.enable = true;

  # Latest kernel: Arrow Lake graphics + Blackwell want a recent one.
  # If the NVIDIA module fails to build against it, fall back to pkgs.linuxPackages (LTS).
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true; # wifi/bluetooth blobs
  hardware.firmware = [ pkgs.sof-firmware ];     # laptop audio DSP (sof-firmware on Arch)
  # Load whichever vendor's microcode matches; harmless on the other.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  documentation.man.enable = true;
  documentation.dev.enable = true; # man-pages

  services.fstrim.enable = true;
  services.udev.packages = [ pkgs.brightnessctl ]; # lets `video` group change brightness

  # Check against what the installer generates; do not bump casually.
  system.stateVersion = lib.mkDefault "26.05";
}
