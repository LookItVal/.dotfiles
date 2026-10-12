# home-manager config for `val`.
#
# Strategy for the first pass: keep the original files in ../../config as the
# single source of truth and just link them into place (see files.nix). Only
# files that cannot work unchanged on NixOS are patched copies in ./patched
# (regenerate with ../scripts/regen-patched.sh). Converting configs to native
# home-manager options (programs.alacritty, services.dunst, ...) can come later.
{ config, lib, pkgs, ... }:
{
  imports = [
    ./files.nix
    ./packages.nix
    ./wallpaper.nix
  ];

  home = {
    username = "val";
    homeDirectory = "/home/val";
    stateVersion = "26.05"; # match system.stateVersion; see TODO.md
  };

  # config/git/config -> declarative (the original hardcodes /usr/bin/gh)
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Quinn Valencia Cecil";
        email = "86853474+LookItVal@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true; # replaces `!/usr/bin/gh auth git-credential`
  };

  # config/user-dirs.dirs
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    download = "${config.home.homeDirectory}/Downloads";
    templates = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
    documents = "${config.home.homeDirectory}/Documents";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # config/mimeapps.list
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/slack" = "slack.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "x-scheme-handler/claude" = "com.anthropic.Claude.desktop";
      "x-scheme-handler/figma" = "figma-linux.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/redisinsight" = "redisinsight.desktop";
    };
    associations.added = {
      "inode/directory" = [ "cursor.desktop" ];
      "application/sql" = [ "code.desktop" "firefox.desktop" ];
      "image/png" = [ "gimp.desktop" "feh.desktop" "com.google.Chrome.desktop" ];
      "image/jpeg" = [ "com.google.Chrome.desktop" "gimp.desktop" ];
    };
  };
}
