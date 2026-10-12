# PLACEHOLDER. Replace with the output of, run on the target machine:
#
#     nixos-generate-config --show-hardware-config > hosts/internal/hardware-configuration.nix
#
# (or write fileSystems/swap by hand to match the layout you choose.)
{ lib, ... }:
{
  assertions = [{
    assertion = false;
    message = "hosts/internal/hardware-configuration.nix is still the placeholder; generate the real one.";
  }];

  nixpkgs.hostPlatform = "x86_64-linux";
}
