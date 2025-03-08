#!/bin/zsh

show_icon=false
ALL_CORES=$(cat $HOME/.config/i3blocks/cpu_usage_expand_state)

usage() {
    echo "Usage: $0 [--icon|-i] [--temp|-t] [--help|-h]"
    echo "Prints the percentage of CPU usage."
    echo "Options:"
    echo "  --icon, -i    Include an icon in the output."
    echo "  --temp, -t    Include the CPU temperature in the output."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

output=""

if $show_icon; then
    output+=" " # adding an icon to the output
fi

if $ALL_CORES; then
    output+=$(top -1bn1 -w 200 | grep "%Cpu" | awk -F'[:,]' '{for(i=2;i<=NF;i+=8) printf "%.1f%% ", 100-$5;}')
else
    output+=$(top -bn1 | awk '/Cpu/ { print 100 - $8 "%" }') # extracting the cpu usage from top
fi

echo "$output"