# zsh on every machine. The config itself is the repo's zshrc + config/zsh,
# linked into ~ by home/common.nix.
{ ... }:
{
  programs.zsh = {
    enable = true;
    # zim (see ../../../zshrc) runs its own compinit and prompt.
    enableGlobalCompInit = false;
    promptInit = "";
  };
}
