#!/bin/zsh

# Install zsh if not already
# zsh now comes standard on osx
if [[ $SHELL != /bin/zsh ]]; then
  echo Installing zsh
  chsh -s /bin/zsh
  echo Done
  echo Effect will not commit until restarting the terminal
else
  echo zsh Already in use
fi

# Installing homebrew
if [[ $(command -v brew) == "" ]]; then
  echo Installing Hombrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo Updating Homebrew
  brew update
  brew upgrade
fi

if [[ $(brew info coreutils) == Error* ]]; then
  echo Installing Core Utilities
  brew install coreutils
else
  echo Core Utilities Currently Installed
fi

# Installing Terminal Tools
. .dotfiles/init/mac/terminal_tools.sh

# Installing Software
. .dotfiles/init/mac/software.sh

# Installing Languages
. .dotfiles/init/mac/languages.sh

# Installing Dependencies
. .dotfiles/init/mac/dependencies.sh 

# Installing Vim-Plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Installing Fonts needed for eriner down the line
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts
echo Fonts installed but will manually need to be set in Terminal Preferences
echo I find myself prefering something simple like 'Go Mono for Powerline'
