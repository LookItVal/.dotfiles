# zsh as val's login shell, plus home-manager to link the dotfiles into ~.
{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # zim (see ../../zshrc) runs its own compinit and prompt.
    enableGlobalCompInit = false;
    promptInit = "";
  };
  users.users.val.shell = pkgs.zsh;

  home-manager = {
    useGlobalPkgs = true;   # use the flake's nixpkgs, not a second copy
    useUserPackages = true;
    # If a file home-manager wants to create already exists, rename it to
    # <name>.hm-bak instead of refusing to switch.
    backupFileExtension = "hm-bak";
    users.val = import ../home/val.nix;
  };
}
