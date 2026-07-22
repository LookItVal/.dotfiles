#!/bin/zsh

show_seconds=false
show_hour12=false

usage() {
    echo "Usage: $0 [--seconds|-s] [--hour12|-H] [--help|-h]"
    echo "Prints the percentage of CPU usage."
    echo "Options:"
    echo "  --seconds, -s    Include the seconds in the output."
    echo "  --hour12, -H    Use 12-hour time format."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --seconds|-s) show_seconds=true ;;
        --hour12|-H) show_hour12=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

STATE_FILE="$HOME/.config/i3blocks/.toggle_time"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + time
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

output=""
hour=$(date "+%I")
case "$hour" in
    01) output+="󱑋" ;;
    02) output+="󱑌" ;;
    03) output+="󱑍" ;;
    04) output+="󱑎" ;;
    05) output+="󱑏" ;;
    06) output+="󱑐" ;;
    07) output+="󱑑" ;;
    08) output+="󱑒" ;;
    09) output+="󱑓" ;;
    10) output+="󱑔" ;;
    11) output+="󱑕" ;;
    12) output+="󱑖" ;;
esac

if [[ $state -eq 1 ]]; then
    output+=" "
    if $show_hour12; then
        output+=$(date "+%I:%M")
    else
        output+=$(date "+%H:%M")
    fi

    if $show_seconds; then
        output+=":"
        output+=$(date "+%S")
    fi
fi

echo " $output  "
