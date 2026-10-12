# X11 + i3, started the same way as on Arch:
#   autologin on tty1 -> ~/.zprofile runs `startx` -> ~/.xinitrc -> i3
# i3lock then locks immediately (see the last `exec i3lock` in the i3 config),
# so the autologin is only a convenience, not an open door.
{ lib, pkgs, xpkg, ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    displayManager.startx.enable = true;
    windowManager.i3 = {
      enable = true;
      # default extraPackages would also pull in plain i3lock, which collides
      # with i3lock-color (same binary name). i3lock-color comes from programs.i3lock.
      extraPackages = [ pkgs.i3status ];
    };
  };

  programs.i3lock = {
    enable = true;          # sets up the PAM service so unlocking works
    package = pkgs.i3lock-color;
  };

  # Arch: /etc/systemd/system/getty@tty1.service.d/autologin.conf
  services.getty = {
    autologinUser = "val";
    autologinOnce = true; # only the first login after boot; later logins need the password
  };

  services.libinput.enable = true; # touchpad; tap/scroll prefs not captured from Arch yet

  # Arch: xdg-desktop-portal-gtk + ~/.config/xdg-desktop-portal/portals.conf (default=gtk)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };
  programs.xfconf.enable = true; # Thunar settings

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa ]; # pacman: firefoxpwa
  };

  environment.systemPackages = [
    (xpkg pkgs "xinit")
  ];
}
