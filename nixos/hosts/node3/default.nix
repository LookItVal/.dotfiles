# node3: only what's specific to this machine.
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "node3";

  # The NixOS version this machine was first installed with. Never change it.
  system.stateVersion = "26.05";
}
