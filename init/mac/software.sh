#!/bin/zsh

# Install Firefox
if [[ $(brew info firefox) == Error* ]]; then
    echo Installing Firefox
    brew install --cask firefox
else
    echo Firefox Currently Installed
    brew info firefox
fi

# Install Spotify
if [[ $(brew info spotify) == Error* ]]; then
    echo Installing Spotify
    brew install --cask spotify
else
    echo Spotify Currently Installed
    brew info spotify
fi
# Hopefully soon we can replace this with Deezer
