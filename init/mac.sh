# Install zsh if not already
# zsh now comes standard on osx
if [ $SHELL != /bin/zsh ]
then
    echo Installing zsh
    chsh -s /bin/zsh
    echo Done
    echo Effect will not commit until restarting the terminal
else
    echo zsh Already in use
fi

# Install homebrew
if [ $(command -v brew) == "" ]
then
    echo Installing Hombrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo Updating Homebrew
    brew update
fi

# Install Tmux
if [ $(which tmux) = "" ]
then
    echo Installing tmux
    brew install tmux
else
    echo Tmux currently installed
    echo $(tmux -V)
fi

# Install Exa
if [ ! ${commands[exa]} ]
then
    echo Installing exa
    brew install exa
else
    echo Exa currently installed
fi

# Installing Fonts needed for eriner down the line
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts
echo Fonts installed but will manually need to be set in Terminal Preferences
echo I find myself prefering something simple like 'Fira Mono for Powerline'

# Update Python
if [ $(python3 -c 'import sys; print(sys.version_info[:][1])') -le 8 ] 
then
    echo Updating Python
    brew reinstall python3
    python3=/usr/local/bin/python3
else
    echo Python version meets defined standards:
    echo $(python3 -V)
fi

# Install Kotlin
if [ $(which kotlin) = "" ]
then
    echo Installing Kotlin
    brew install kotlin
else
    echo Kotlin currently installed:
    echo $(kotlin -version)
fi

# Other languages may go here (Haskell, Go, Rust, ect) but until we start using them they do not need to be added
