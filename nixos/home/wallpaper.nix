# Arch: /etc/systemd/system/wallpaper.{service,timer} + wallpaper.sh (system units)
# NixOS: a *user* timer/service, because the script needs the user's X session.
{ pkgs, lib, xpkg, ... }:
{
  systemd.user.services.wallpaper = {
    Unit.Description = "Wallpaper changing service";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/wallpaper.sh %h/.local/share/wallpapers";
      # Needs DISPLAY/XAUTHORITY: ~/.xinitrc runs `systemctl --user import-environment DISPLAY XAUTHORITY`.
      Environment = [
        "PATH=${lib.makeBinPath [
          pkgs.zsh pkgs.feh pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.findutils
          (xpkg pkgs "xrandr")
        ]}"
      ];
    };
  };

  systemd.user.timers.wallpaper = {
    Unit.Description = "Change wallpapers every 3 hours";
    Timer = {
      OnBootSec = "10min";
      OnUnitActiveSec = "3h";
      Unit = "wallpaper.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
