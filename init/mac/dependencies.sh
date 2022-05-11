#!/bin/zsh

# Installing Node.js for Github Copilot
if [[ $(brew info node) == *Error ]]; then
    echo Installing Node.js
    brew install node
else
    echo Node.js Currently Installed
    brew info node
fi


