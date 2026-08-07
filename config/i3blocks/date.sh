#!/bin/zsh

show_year=false

usage() {
    echo "Usage: $0 [--year|-y] [--help|-h]"
    echo "Prints the current date block output."
    echo "Options:"
    echo "  --year, -y    Include the year in the output."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --year|-y) show_year=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

STATE_FILE="$HOME/.config/i3blocks/.toggle_date"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: date, 2: day of week, 3: day of week + full date
state=1
if [[ -f "$STATE_FILE" ]]; then
    saved_state=$(<"$STATE_FILE")
    if [[ "$saved_state" =~ '^[0-3]$' ]]; then
        state=$saved_state
    fi
fi

if [[ -n "$button" ]]; then
    state=$(( (state + 1) % 4 ))
    print -r -- "$state" >| "$STATE_FILE"
fi

output="󰸗"
case "$state" in
    0)
        ;;
    1)
        output+=" "
        output+=$(date "+%B %d")
        if $show_year; then
            output+=" "
            output+=$(date "+%Y")
        fi
        ;;
    2)
        output+=" "
        output+=$(date "+%A")
        ;;
    3)
        output+=" "
        output+=$(date "+%A, %B %d, %Y")
        ;;
esac


echo " $output  "