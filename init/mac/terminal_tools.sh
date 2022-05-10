#!/bin/zsh

# Installing iTerm2
if [[ $(brew info iterm2) == Error* ]]; then
    echo Installing iTerm2
    brew install --cask iterm2
else
    echo iTerm2 Currently Installed
    brew info iterm2
fi

# Installing Tmux
if [[ $(which tmux) == "" ]]; then
    echo Installing Tmux
    brew install tmux
else
    echo Tmux Currently Installed
    tmux -V
fi

# Installing Neovim
if [[ $(which nvim) == "" ]];then
    echo Installing Neovim
    brew install neovim
else
    echo Neovim Currently Installed
    nvim -v
fi

# Installing Exa
if [[ $(which exa) == "" ]]; then
    echo Installing Exa
    brew install exa
else
    echo Exa Currently Installed
    exa -v
fi

# Installing Bat
if [[ $(which bat) == "" ]]; then
    echo Installing Bat
    brew install bat
else
    echo Bat Currently Installed
    bat -V
fi

# Installing Fzf
if [[ $(which fzf) == "" ]]; then
    echo Installing Fzf
    brew install fzf
else
    echo Fzf Currently Installed
    fzf --version
fi

# Installing fd
if [[ $(which fd) == "" ]]; then
    echo Installing fd 
    brew install fd 
else
    echo fd Currently Installed
    fd -V
fi
# (Used by fzf)

# Installing Ripgrep
if [[ $(which rg) == "" ]]; then
    echo Installing Ripgrep
    brew install ripgrep
else
    echo Ripgrep Currently Installed
    rg -V
fi
# (Also Used by Fzf)
