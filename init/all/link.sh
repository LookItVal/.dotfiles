#!/bin/zsh

cd
if [ ! -d .dotfiles ]; then
  echo "No .dotfiles directory found"
  exit 1
fi
if [ -d .config ]; then
  echo ".config directory already exists would you like to delete it? (y/n)"
  read answer
  if [ $answer = "y" ]; then
    rm -rf .config
  else
    echo "Leaving existing .config directory"
  fi
fi
ln -s .dotfiles/config .config
if [ -f .zprofile ]; then
  echo ".zprofile already exists would you like to delete it? (y/n)"
  read answer
  if [ $answer = "y" ]; then
    rm .zprofile
  else
    echo "Leaving existing .zprofile"
  fi
fi
ln -s .dotfiles/profile.sh .zprofile
if [ -f .zshrc ]; then
  echo ".zshrc already exists would you like to delete it? (y/n)"
  read answer
  if [ $answer = "y" ]; then
    rm .zshrc
  else
    echo "Leaving existing .zshrc"
  fi
fi
ln -s .dotfiles/zshrc .zshrc
if [ -f .xinitrc ]; then
  echo ".xinitrc already exists would you like to delete it? (y/n)"
  read answer
  if [ $answer = "y" ]; then
    rm .xinitrc
  else
    echo "Leaving existing .xinitrc"
  fi
fi
ln -s .dotfiles/xinitrc .xinitrc
