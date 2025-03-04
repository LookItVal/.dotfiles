#!/bin/zsh


link_files() {
  for file in "$@"; do
    if [ ! -e $HOME/.dotfiles/$file ]; then
      echo "File or Directory $file does not exist in .dotfiles directory"
      continue
    fi
    if [ -f $HOME/.dotfiles/$file ]; then
      link_file $HOME/.dotfiles/$file $HOME/.$file
      continue
    fi
    if [ -d $HOME/.dotfiles/$file ]; then
      link_folder $HOME/.dotfiles/$file $HOME/.$file
    fi
  done
  return 0
}

link_folder() {
  if [ -z $1 ] || [ -z $2 ]; then
    echo "No directory specified"
    return 1
  fi
  local src=$1
  local dest=$2
  if [ ! -d $dest ]; then
    ln -s $src $dest
    echo "Linked all of $src/"
    return 0
  fi
  if [ -L $dest ]; then
    rm $dest
    ln -s $src $dest
    echo "Linked all of $src directory"
    return 0
  fi
  for file in $src/*; do
    if [ -f $file ]; then
      link_file $file $dest/$(basename $file)
      continue
    fi
    if [ -d $file ]; then
      link_folder $file $dest/$(basename $file)
      continue
    fi
  done
  return 0
}


link_file() {
  if [ -z $1 ] || [ -z $2 ]; then
    echo "No file specified"
    return 1
  fi
  local src=$1
  local dest=$2
  if [ ! -f $dest ]; then
    ln -s $src $dest
    return 0
  fi
  if [ -L $dest ]; then
    rm $dest
    ln -s $src $dest
    echo "Linked $src"
    return 0
  fi
  echo "File $dest already exists in home directory"
  echo "Line Count: "
  wc -l $dest
  head $dest
  echo "Do you want to overwrite this file? (y/*)"
  read answer
  if [ "$answer" != "y" ]; then
    return 0
  fi
  rm $dest
  ln -s $src $dest
  echo "Linked $src"
  return 0
}

