#!/bin/zsh

# Function to install yay
install_yay() {
  echo Installing Yay
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay
}