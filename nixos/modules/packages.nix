# System-wide packages: everything the i3 session, the i3blocks/screenshot/
# volume scripts, and a sane terminal environment need on PATH.
# GUI apps live in ../home/packages.nix.
#
# Anything I wasn't sure exists in nixpkgs under this name goes through `maybe`,
# which warns at eval time instead of failing the whole build. See INVENTORY.md.
{ config, lib, pkgs, xpkg, ... }:
let
  x = xpkg pkgs;
  maybe = name:
    if pkgs ? ${name} then [ pkgs.${name} ]
    else lib.warn "nixos config: pkgs.${name} not found, skipping" [ ];
in
{
  environment.systemPackages =
    (with pkgs; [
      # --- shell & CLI (pacman: zsh bat eza fd fzf ripgrep jq htop ...) ---
      zsh git curl wget unzip zip _7zz unrar file tree
      bat eza fd fzf ripgrep jq htop neovim tmux
      bind                 # dig/nslookup (pacman: bind)
      fastfetch
      magic-wormhole
      ps_mem
      texinfo
      lsof pciutils usbutils
      lm_sensors           # `sensors` (i3blocks cpu_temperature)
      iproute2             # `ip` (i3blocks network)
      wirelesstools        # `iwgetid` (i3blocks network)
      gh

      # --- i3 session ---
      i3blocks
      rofi
      dunst
      picom
      feh
      dex                  # `dex --autostart` in the i3 config
      xss-lock
      autorandr
      xbindkeys
      xdotool
      xclip
      xsel
      maim
      brightnessctl
      libnotify            # notify-send (every script)
      pulseaudio           # pactl / paplay clients; the server is pipewire-pulse
      (if config.my.lean then ffmpeg else ffmpeg-full) # record-screen: x11grab + libx264
      alacritty
      networkmanagerapplet # nm-applet
      networkmanager_dmenu
      bluetui
      nwg-look
      papirus-icon-theme
      flameshot

      # --- misc runtime ---
      efibootmgr
      os-prober
    ])
    ++ [
      (x "xrandr")
      (x "xrdb")
      (x "xset")
      (x "xsetroot")
      (x "xinput")
      (x "xprop")
      (x "xev")
      (x "xwininfo")
      (x "xhost")
      (x "setxkbmap")
      (x "xmodmap")
    ]
    ++ maybe "catppuccin-papirus-folders"
    ++ lib.optional (pkgs ? catppuccin-gtk)
      (pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "macchiato";
        size = "standard";
      });
}
