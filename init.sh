#!/bin/zsh

os=$(uname -s)
if [ $os = "Darwin" ]; then
  os="mac"
fi
if [ $os =  "Linux" ]; then
  # which distro
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

# ALL MAC SPECIFIC THINGS

# ALL ARCH SPECIFIC THINGS

# ALL GENERAL THINGS
