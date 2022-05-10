#!/bin/zsh

if [ -z "$TMUX" ]; then
    tmux attach || exec tmux new-session
fi