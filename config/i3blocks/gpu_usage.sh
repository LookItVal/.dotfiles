#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_gpu_usage"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + GPU usage, 2: icon + GPU usage + VRAM usage
state=2
if [[ -f "$STATE_FILE" ]]; then
    saved_state=$(<"$STATE_FILE")
    if [[ "$saved_state" =~ '^[0-2]$' ]]; then
        state=$saved_state
    fi
fi

if [[ -n "$button" ]]; then
    state=$(( (state + 1) % 3 ))
    print -r -- "$state" >| "$STATE_FILE"
fi

icon="󰢮"
output="$icon"

gpu_payload=$("$HOME/.config/i3blocks/gpu_stats.sh" 2>/dev/null)
if [[ -z "$gpu_payload" || "$gpu_payload" == NA\|* ]]; then
    if [[ $state -ne 0 ]]; then
        output+=" N/A"
    fi
    echo " $output"
    exit 0
fi

IFS='|' read -r gpu_util mem_used_mib mem_total_mib _gpu_temp <<< "$gpu_payload"

if [[ $state -eq 1 ]]; then
    output+=" ${gpu_util}%"
elif [[ $state -eq 2 ]]; then
    mem_used_gib=$(awk -v v="$mem_used_mib" 'BEGIN { printf "%.1f", v / 1024 }')
    mem_total_gib=$(awk -v v="$mem_total_mib" 'BEGIN { printf "%.1f", v / 1024 }')
    output+=" ${gpu_util}% ${mem_used_gib}/${mem_total_gib}GiB"
fi

echo " $output  "
