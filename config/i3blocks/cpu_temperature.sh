#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_cpu_temp"
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

temp=$(sensors 2>/dev/null | awk '
/^Package id 0:/ {
    value=$4
    gsub(/\+|°C/, "", value)
    printf "%d", value + 0
    exit
}
/^Tctl:/ {
    value=$2
    gsub(/\+|°C/, "", value)
    printf "%d", value + 0
    exit
}
/^Tdie:/ {
    value=$2
    gsub(/\+|°C/, "", value)
    printf "%d", value + 0
    exit
}
')
[[ -z "$temp" ]] && temp=0

icon=""
color=\#181926
if [[ $temp -ge 90 ]]; then
    icon=""
    color=\#d20f39
elif [[ $temp -ge 85 ]]; then
    icon=""
    color=\#e64553
elif [[ $temp -ge 80 ]]; then
    icon=""
    color=\#fe640b
elif [[ $temp -ge 70 ]]; then
    icon=""
elif [[ $temp -ge 65 ]]; then
    icon=""
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

echo $output
echo $icon
echo $color
