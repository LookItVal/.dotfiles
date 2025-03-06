#!/bin/zsh

show_icon=false
show_fraction=false
show_percentage=false

usage() {
    echo "Usage: $0 [--icon|-i] [--fraction|-f] [--percentage|-p] [--help|-h]"
    echo "Prints the percentage of GPU usage. Requires nvidia-smi."
    echo "Options:"
    echo "  --icon, -i         Include an icon in the output."
    echo "  --fraction, -f     Include the memory usage as a fraction in the output."
    echo "  --percentage, -p   Include the memory usage as a percentage in the output."
    echo "  --help, -h         Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --fraction|-f) show_fraction=true ;;
        --percentage|-p) show_percentage=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

output=""

if $show_icon; then
    output+=" " # adding an icon to the output
fi

if $show_fraction; then
    output+=" "
    output+=$(top -bn1 | awk '/MiB Mem/ { printf "%.1f", $8/1024 }')
    output+="/"
    output+=$(top -bn1 | awk '/MiB Mem/ { printf "%.1f", $4/1024 }')
    output+="GiB"
fi

if $show_percentage; then
    output+=" "
    output+=$(top -bn1 | awk '/MiB Mem/ { printf "%.0f", $8/$4*100 }')
    output+="%"
fi

echo "$output"