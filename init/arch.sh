#!/bin/zsh

. .dotfiles/init/arch/utilities.sh

# Zsh
if [[ $SHELL != /bin/zsh ]]; then
  echo Installing zsh
  if [[ $(which zsh) == "" ]]; then
    sudo pacman -S zsh
  fi
  chsh -s /bin/zsh
  echo Done
  echo Effect will not commit until restarting the terminal
else
  echo zsh in use
fi

# Yay
if [[ $(which yay) == "" ]]; then
  install_yay
else
  echo Yay installed
fi

sudo rm /etc/systemd/system/wallpaper.service
sudo rm /etc/systemd/system/wallpaper.timer
sudo rm /etc/systemd/system/wallpaper.sh
sudo rm -r /etc/systemd/system/wallpapers
sudo cp .dotfiles/arch/wallpaper.service /etc/systemd/system/wallpaper.service
sudo cp .dotfiles/arch/wallpaper.timer /etc/systemd/system/wallpaper.timer
sudo cp .dotfiles/arch/wallpaper.sh /etc/systemd/system/wallpaper.sh
sudo mkdir /etc/systemd/system/wallpapers
sudo cp .dotfiles/arch/wallpapers/* /etc/systemd/system/wallpapers
systemctl enable wallpaper.timer
systemctl start wallpaper.timer

sudo pacman -Syu
sudo pacman -S --noconfirm exa bat ripgrep fd fzf neovim alacritty i3-wm xorg xorg-xinit xorg-server i3lock i3status rofi pulseaudio pavucontrol firefox feh spotify-launcher i3blocks nodejs python ipython python-pip nerd-fonts vlc
yay visual-studio-code-bin i3lock-color micromamba nvm