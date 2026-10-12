# PLACEHOLDER. After the bootstrap install (../../INSTALL.md), replace this file with
# the one the installer generated:
#
#     cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/nixos/hosts/internal/
#     git -C ~/.dotfiles add nixos/hosts/internal/hardware-configuration.nix
#
# It should contain fileSystems."/" (p8), fileSystems."/efi" (p1), fileSystems."/boot"
# (p5) and swapDevices (p6), all by UUID.
{ lib, ... }:
{
  assertions = [{
    assertion = false;
    message = "hosts/internal/hardware-configuration.nix is still the placeholder; copy /etc/nixos/hardware-configuration.nix from the installed system.";
  }];

  nixpkgs.hostPlatform = "x86_64-linux";
}
