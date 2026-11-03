# Arch had ~80 Nerd Font packages. Installing all of them is ~2-3 GB, which hurts on
# a USB stick, so by default only the fonts the configs actually reference plus a
# few favourites are installed. Flip `my.fonts.allNerdFonts` to get everything.
{ config, lib, pkgs, ... }:
let
  cfg = config.my.fonts;
  curated = with pkgs.nerd-fonts; [
    fira-code     # i3 bar, alacritty, gtk
    fira-mono     # dunst ("Fira Mono")
    hack          # alacritty italic/bold-italic
    symbols-only
    jetbrains-mono
    meslo-lg
    iosevka
    caskaydia-cove
    roboto-mono
    sauce-code-pro
    ubuntu
    ubuntu-mono
    victor-mono
    mononoki
    inconsolata
    noto
    dejavu-sans-mono
  ];
  everything = lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts);
in
{
  options.my.fonts.allNerdFonts = lib.mkEnableOption "every Nerd Font (very large)";

  config = {
    fonts = {
      enableDefaultPackages = true;
      packages = [ pkgs.jetbrains-mono ]
        ++ (if cfg.allNerdFonts then everything else curated);

      fontconfig.defaultFonts = {
        monospace = [ "FiraCode Nerd Font" ]; # i3 uses `font pango:monospace 8`
      };
    };
  };
}
