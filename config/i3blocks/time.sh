#!/bin/zsh

show_icon=false
show_seconds=false
show_hour12=false

usage() {
    echo "Usage: $0 [--icon|-i] [--seconds|-s] [--hour12|-H] [--help|-h]"
    echo "Prints the percentage of CPU usage."
    echo "Options:"
    echo "  --icon, -i    Include an icon in the output."
    echo "  --seconds, -s    Include the seconds in the output."
    echo "  --hour12, -H    Use 12-hour time format."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --seconds|-s) show_seconds=true ;;
        --hour12|-H) show_hour12=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

output=""
if $show_icon; then
    if [[ $(date "+%I") -eq 01 ]]; then
        output+="󱑋 "
    fi
    if [[ $(date "+%I") -eq 02 ]]; then
        output+="󱑌 "
    fi
    if [[ $(date "+%I") -eq 03 ]]; then
        output+="󱑍 "
    fi
    if [[ $(date "+%I") -eq 04 ]]; then
        output+="󱑎 "
    fi
    if [[ $(date "+%I") -eq 05 ]]; then
        output+="󱑏 "
    fi
    if [[ $(date "+%I") -eq 06 ]]; then
        output+="󱑐 "
    fi
    if [[ $(date "+%I") -eq 07 ]]; then
        output+="󱑑 "
    fi
    if [[ $(date "+%I") -eq 08 ]]; then
        output+="󱑒 "
    fi
    if [[ $(date "+%I") -eq 09 ]]; then
        output+="󱑓 "
    fi
    if [[ $(date "+%I") -eq 10 ]]; then
        output+="󱑔 "
    fi
    if [[ $(date "+%I") -eq 11 ]]; then
        output+="󱑕 "
    fi
        if [[ $(date "+%I") -eq 12 ]]; then
        output+="󱑖 "
    fi
fi

if $show_hour12; then
    output+=$(date "+%I:%M")
else
    output+=$(date "+%H:%M")
fi

if $show_seconds; then
    output+=":"
    output+=$(date "+%S")
fi

echo " $output"
