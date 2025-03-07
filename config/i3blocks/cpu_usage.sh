#!/bin/zsh

show_icon=false
show_use=true

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

if $show_use; then
    output+=$(top -bn1 | awk '/Cpu/ { print 100 - $8 "%" }') # extracting the cpu usage from top
fi

echo "$output"