#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_gpu_temp"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + temperature
state=1
if [[ -f "$STATE_FILE" ]]; then
    saved_state=$(<"$STATE_FILE")
    if [[ "$saved_state" =~ '^[0-1]$' ]]; then
        state=$saved_state
    fi
fi

if [[ -n "$button" ]]; then
    state=$(( (state + 1) % 2 ))
    print -r -- "$state" >| "$STATE_FILE"
fi

gpu_payload=$("$HOME/.config/i3blocks/gpu_stats.sh" 2>/dev/null)
if [[ -z "$gpu_payload" || "$gpu_payload" == NA\|* ]]; then
    temp=0
else
    IFS='|' read -r _gpu_util _mem_used_mib _mem_total_mib temp <<< "$gpu_payload"
fi

icon=""
color=\#181926
if [[ $temp -ge 80 ]]; then
    icon=""
    color=\#d20f39
elif [[ $temp -ge 70 ]]; then
    icon=""
    color=\#e64553
elif [[ $temp -ge 65 ]]; then
    icon=""
    color=\#fe640b
elif [[ $temp -le 30 ]]; then
    icon=""
    color=\#1e66f5
fi
output=" "
output+="$icon"
if [[ $state -eq 1 ]]; then
    output+=" "
    output+="$temp°C"
fi

echo "$output"
echo "$icon"
echo "$color"