#!/bin/zsh

# Update Python
if [[ $(python3 -c 'import sys; print(sys.version_info[:][1])') -le 8 ]]; then
    echo Updating Python
    brew reinstall python3
    python3=/usr/local/bin/python3
else
    echo Python version meets defined standards:
    python3 -V
fi

#Install Kotlin
if [[ $(which kotlin) = "" ]]; then
    echo Installing Kotlin
    brew install kotlin
else
    echo Kotlin Currently Installed:
    kotlin -version
fi

# Other languages can go here (rust, go, haskell) but untill i use them they wont be installed

