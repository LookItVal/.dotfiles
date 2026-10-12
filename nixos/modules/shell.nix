{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # zim (see home/patched/zshrc) runs its own compinit and prompt.
    enableGlobalCompInit = false;
    promptInit = "";
  };

  environment.shells = [ pkgs.zsh ];
  environment.variables.EDITOR = "nvim";
  environment.variables.TERMINAL = "alacritty"; # i3-sensible-terminal
}
