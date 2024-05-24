#!/bin/zsh

cd $HOME

. .dotfiles/utilities.sh

os=$(uname -s)
if [ $os = "Darwin" ]; then
  os="mac"
fi
if [ $os =  "Linux" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    os=$ID
  else
    os="unknown"
  fi
fi

if [ $os = "unknown" ]; then
  echo "Unknown OS"
  exit 1
fi

# ALL UBUNTU SPECIFIC THINGS
if [ $os = "ubuntu" ]; then
  sudo apt update
  sudo apt install -y zsh curl git exa
  sudo snap install nvim --classic
  # NOTE this assumes it exists as a WSL
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ln -s ~/.dotfiles/config/alacritty/alacritty.toml "/mnt/c/Users/Audio Suite/AppData/Roaming/alacritty/alacritty.toml"
  ln -s ~/.dotfiles/config/alacritty/catppuccin-macchiato.toml "/mnt/c/Users/Audio Suite/AppData/Roaming/alacritty/catppuccin-macchiato.toml"
fi

# ALL MAC SPECIFIC THINGS

# ALL ARCH SPECIFIC THINGS

# ALL GENERAL THINGS

# link files
link_files zshrc config
