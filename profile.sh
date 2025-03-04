#!/bin/zsh

# get os
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

if [ $os != "arch" ]; then
  if [ -z "$TMUX" ]; then
    tmux attach || exec tmux new-session
  fi
fi

if [ $os = "arch" ]; then
  exec startx
fi