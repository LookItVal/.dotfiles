# node2: only what's specific to this machine.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    # Off until the join token comes from sops.
    # ../../modules/server/k3s-agent.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "node2";

  # The NixOS version this machine was first installed with. Never change it.
  system.stateVersion = "26.05";
}
