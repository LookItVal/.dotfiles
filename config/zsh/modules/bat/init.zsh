#!/bin/zsh
# Sets bat as default for cat and less using main theme

# Check for bat
if (( ! ${+commands[bat]} )); then
    return 1
fi

# Link with global theme
export BAT_THEME="GitHub"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias cat='bat'
alias less='bat'
