#!/bin/zsh

ALL_CORES=$(cat $HOME/.config/i3blocks/cpu_usage_expand_state)

if [[ $ALL_CORES == "true" ]]; then
    echo "false" > $HOME/.config/i3blocks/cpu_usage_expand_state
else
    echo "true" > $HOME/.config/i3blocks/cpu_usage_expand_state
fi

sh $HOME/.config/i3blocks/cpu_usage.sh -i
