#!/bin/zsh

# Installing Node.js for Github Copilot
if [[ $(brew info node) == *Error ]]; then
    echo Installing Node.js
    brew install node
else
    echo Node.js Currently Installed
    brew info node
fi

# Updating Less for Bat (I know, seems redundant doesn't it?)
if [[ $(brew info less) == *Error ]]; then
    echo Installing Less
    brew install less
else
    echo Less Currently Installed
    brew info less
fi

