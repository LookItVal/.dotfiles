{ pkgs, ... }:
{
  users.users.val = {
    isNormalUser = true;
    description = "Quinn Valencia Cecil";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "video" "audio" "docker" "networkmanager" ];
    # TEST-STICK ONLY. i3 locks the screen at login (see i3 config), so you
    # need a working password. Change it with `passwd` on first boot, then
    # replace this with hashedPasswordFile / hashedPassword.
    initialPassword = "changeme";
  };

  security.sudo.wheelNeedsPassword = true;
}
