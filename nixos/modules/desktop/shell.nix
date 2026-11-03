{ pkgs, ... }:
{
  environment.shells = [ pkgs.zsh ];
  environment.variables.EDITOR = "nvim";
  environment.variables.TERMINAL = "alacritty"; # i3-sensible-terminal
}
