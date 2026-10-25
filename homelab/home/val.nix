# home-manager config for val on the servers.
#
# The dotfiles are linked "live": ~/.zshrc points at ~/.dotfiles/zshrc itself,
# not a copy, so `git pull` is enough to pick up changes, no rebuild needed.
# Needs the repo checked out at ~/.dotfiles.
{ config, pkgs, ... }:
let
  live = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
in
{
  home = {
    username = "val";
    homeDirectory = "/home/val";
    stateVersion = "26.05"; # like system.stateVersion: never change it
  };

  home.file.".zshrc".source = live "zshrc";

  # Whole folders, same as on the laptop. zim downloads itself into
  # ~/.config/zsh/zim and lazy.nvim writes lazy-lock.json next to the
  # config; both are gitignored in the repo.
  xdg.configFile = {
    "zsh".source = live "config/zsh";
    "nvim".source = live "config/nvim";
  };

  # Tools the zsh setup expects.
  home.packages = with pkgs; [
    curl # zim downloads itself on first run
    eza
    bat
    fzf
  ];
}
