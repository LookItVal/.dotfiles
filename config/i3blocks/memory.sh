#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_memory"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + percentage, 2: icon + fraction
state=1
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

read -r mem_total_kib mem_available_kib <<< "$(awk '
/^MemTotal:/ { total=$2 }
/^MemAvailable:/ { avail=$2 }
END { printf "%d %d", total, avail }
' /proc/meminfo)"

if [[ -z "$mem_total_kib" || "$mem_total_kib" -le 0 ]]; then
    mem_usage_pct="0"
    mem_used_gib="0.0"
    mem_total_gib="0.0"
else
    mem_usage_pct=$(awk -v t="$mem_total_kib" -v a="$mem_available_kib" 'BEGIN { printf "%.0f", ((t - a) * 100) / t }')
    mem_used_gib=$(awk -v t="$mem_total_kib" -v a="$mem_available_kib" 'BEGIN { printf "%.1f", (t - a) / 1024 / 1024 }')
    mem_total_gib=$(awk -v t="$mem_total_kib" 'BEGIN { printf "%.1f", t / 1024 / 1024 }')
fi

icon=""
output="$icon"
if [[ $state -eq 1 ]]; then
    output+=" ${mem_usage_pct}%"
elif [[ $state -eq 2 ]]; then
    output+=" ${mem_used_gib}/${mem_total_gib}GiB"
fi

echo " $output "