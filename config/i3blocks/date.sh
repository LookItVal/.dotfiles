#!/bin/zsh

show_icon=false
show_year=false

usage() {
    echo "Usage: $0 [--icon|-i] [--year|-y] [--help|-h]"
    echo "Prints the percentage of CPU usage."
    echo "Options:"
    echo "  --icon, -i    Include an icon in the output."
    echo "  --year, -y    Include the year in the output."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --year|-y) show_year=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

output=""
if $show_icon; then
    output+="󰸗 "
fi

output+=$(date "+%B %d")

if $show_year; then
    output+=" "
    output+=$(date "+%Y")
fi

echo "$output"