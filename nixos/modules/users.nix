{ pkgs, ... }:
{
  users.users.val = {
    isNormalUser = true;
    description = "Quinn Valencia Cecil";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "video" "audio" "docker" "networkmanager" ];
    # Only applies when the user is first created (fresh `usb` stick installs).
    # On `internal`, val already exists from the bootstrap install, so the password
    # set there with `passwd` is kept and this line has no effect.
    initialPassword = "changeme";
  };

  security.sudo.wheelNeedsPassword = true;
}
