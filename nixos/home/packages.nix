# User-level GUI apps and dev tools (pacman explicit + AUR). See INVENTORY.md.
{ lib, pkgs, osConfig ? null, ... }:
let
  # my.lean (see ../modules/lean.nix) drops the `heavy` list for small test sticks.
  lean = osConfig != null && (osConfig.my.lean or false);
  maybe = name:
    if pkgs ? ${name} then [ pkgs.${name} ]
    else lib.warn "nixos config: pkgs.${name} not found, skipping" [ ];

  heavy = with pkgs; [
    code-cursor       # cursor-bin
    dbeaver-bin
    gimp
    inkscape
    libreoffice
    obsidian
    spotify           # spotify-launcher
    moonlight-qt
    figma-linux
    slack
  ];
in
{
  home.packages =
    (with pkgs; [
      # browsers
      google-chrome

      # editors / dev
      vscode            # visual-studio-code-bin
      claude-code
      nodejs            # also provides npm; `nvm` has no nixpkgs equivalent (use nodejs/fnm/devshells)
      php
      phpPackages.composer
      (python3.withPackages (ps: [ ps.pip ps.ipython ]))
      mariadb.client    # mariadb-clients
      docker-compose

      # media
      vlc
      spicetify-cli
      guvcview

      # file/system tools
      xarchiver
      pwvucontrol
    ])
    ++ lib.optionals (!lean) heavy
    ++ maybe "fontpreview";
  # redisinsight omitted: nixpkgs build uses EOL electron-41 (marked insecure).
  # Re-add when fixed upstream, or use permittedInsecurePackages if you accept the risk.
  # Not packaged anywhere I know of: claude-desktop (use Claude in the browser, or a
  # community flake), yay (n/a), nvm (see above).
}
