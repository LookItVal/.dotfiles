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
  # only on a real console login on tty1, never in a terminal emulator
  # or a non-interactive shell (e.g. tooling that sources this file)
  if [[ -o interactive && -z $DISPLAY && $TTY == /dev/tty1 ]]; then
    exec startx
  fi
fi
