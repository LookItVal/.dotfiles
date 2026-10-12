{ pkgs, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.podman.enable = true; # no dockerCompat: docker is the `docker` command
  # (lerd's podman/DNS/port setup is in lerd.nix, enabled per host)

  services.gvfs.enable = true;          # Thunar trash/mounts/network
  services.tumbler.enable = true;       # thumbnails
  services.upower.enable = true;

  programs.dconf.enable = true;         # GTK settings backend (nwg-look etc.)
  security.polkit.enable = true;

  # Arch had cronie enabled; nothing in the repo uses it. Left off on purpose.
  # services.cron.enable = true;
}
