#!/bin/zsh

show_icon=false
show_temp=true

usage() {
    echo "Usage: $0 [--icon|-i] [--temp|-t] [--help|-h]"
    echo "Prints the CPU temperature."
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

temp=$(sensors | awk '/^Package id 0/ {print substr($4, 2, 2)}')
icon=""
color=\#181926
if [[ $temp -ge 90 ]]; then
    icon=""
    color\#d20f39
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
    color=\#fe640b
elif [[ $temp -le 30 ]]; then
    icon=""
    color=\#1e66f5
fi
output=" "

if $show_icon; then
    output+="$icon "
fi

if $show_temp; then
    output+="$temp°C"
fi

echo $output
echo $icon
echo $color
