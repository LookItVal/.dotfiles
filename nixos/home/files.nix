# Links the dotfiles into $HOME.
#
# Sources are relative paths into the repo (../../config etc). That only works
# when the flake is evaluated as a *git* flake (nixos-rebuild --flake ./nixos#host
# from inside the repo) so that the whole repo is the flake source. It will
# fail with `path:` flakes. Also: only git-TRACKED files are visible to the flake.
{ config, lib, pkgs, ... }:
let
  repo = ../..;
  cfg = repo + "/config";
  patched = ./patched;

  # Live (editable) link to the checkout instead of a read-only store copy.
  # Needs the repo at ~/.dotfiles on the target machine.
  live = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
in
{
  xdg.configFile = {
    # --- patched copies (see scripts/regen-patched.sh) ---
    "i3".source = patched + "/i3";
    "i3blocks".source = patched + "/i3blocks";
    "dunst/dunst-sound.sh".source = patched + "/dunst/dunst-sound.sh";

    # --- linked as-is from config/ ---
    "picom/picom.conf".source = cfg + "/picom/picom.conf";
    "rofi".source = cfg + "/rofi";
    "alacritty".source = cfg + "/alacritty";
    "dunst/dunstrc".source = cfg + "/dunst/dunstrc";
    "dunst/sounds".source = cfg + "/dunst/sounds";
    "fastfetch".source = cfg + "/fastfetch";
    "autorandr".source = cfg + "/autorandr";
    "networkmanager-dmenu/config.ini".source = cfg + "/networkmanager-dmenu/config.ini";
    "xsettingsd/xsettingsd.conf".source = cfg + "/xsettingsd/xsettingsd.conf";
    "gtk-3.0/settings.ini".source = cfg + "/gtk-3.0/settings.ini";
    "tmux/tmux.conf".source = cfg + "/tmux/tmux.conf";

    # zsh: link individual entries so ~/.config/zsh stays a real, writable dir
    # (zim downloads itself into ~/.config/zsh/zim on first run).
    "zsh/.zimrc".source = cfg + "/zsh/.zimrc";
    "zsh/modules".source = cfg + "/zsh/modules";

    # nvim: lazy.nvim writes lazy-lock.json next to the config, so link the live checkout.
    "nvim".source = live "config/nvim";
  };

  home.file = {
    ".zshrc".source = patched + "/zshrc";
    ".zprofile".source = patched + "/zprofile";
    ".xinitrc".source = repo + "/xinitrc"; # works unchanged

    ".local/bin/wallpaper.sh" = {
      source = patched + "/wallpaper.sh";
      executable = true;
    };

    # arch/wallpapers (285 MB) -> ~/.local/share/wallpapers
    ".local/share/wallpapers".source = repo + "/arch/wallpapers";

    # ~/.xbindkeysrc was never committed to the repo; reconstructed from the live file.
    ".xbindkeysrc".text = ''
      "xdotool key Return"
          b:9
      "xdotool key Delete"
          b:8
    '';
  };
}
