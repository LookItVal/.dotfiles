#!/bin/zsh

show_icon=false
show_network=false
show_ip=false

usage() {
    echo "Usage: $0 [--icon|-i] [--network|-n] [--ip|-I] [--help|-h]"
    echo "Prints the network usage."
    echo "Options:"
    echo "  --icon, -i    Include an icon in the output."
    echo "  --network, -n Include the network name in the output."
    echo "  --ip, -I      Include the IP address in the output."
    echo "  --help, -h    Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --network|-n) show_network=true ;;
        --ip|-I) show_ip=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

output=""

if $show_icon; then
    output+="󰣺 " #TODO CHANGE THIS MAKE THIS DYNAMIC
fi

if $show_network; then
    output+="$(nmcli -t -f NAME c show --active | head -n 1)"
fi

if $show_ip; then
    output+=" $(nmcli -p device show | awk '/IP4.ADDRESS/ { print $2 }')"
fi

echo "$output"