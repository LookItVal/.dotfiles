#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_network"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + network, 2: icon + network + ip, 3: icon + ip
state=2
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

if command -v nmcli >/dev/null 2>&1; then
    data=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | awk -F: '$3 == "connected" && ($2 == "wifi" || $2 == "ethernet") { print; exit }')
else
    data=""
fi

iface_type=$(echo "$data" | awk -F: '{print $2}')
conn_name=$(echo "$data" | awk -F: '{print $4}')

case "$iface_type" in
    ethernet)
        icon=""
        network_name="Ethernet"
        ;;
    wifi)
        signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')
        if [[ -z "$signal" ]]; then
            icon="󰣻"
        elif (( signal > 75 )); then
            icon="󰣺"
        elif (( signal > 50 )); then
            icon="󰣸"
        elif (( signal > 25 )); then
            icon="󰣶"
        else
            icon="󰣴"
        fi
        network_name="$conn_name"
        ;;
    *)
        icon="󰣽"
        network_name="Disconnected"
        ;;
esac

ip_addr=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')

output="$icon"
if [[ $state -eq 1 ]]; then
    output+=" $network_name"
elif [[ $state -eq 2 ]]; then
    output+=" $network_name"
    if [[ -n "$ip_addr" ]]; then
        output+=" | $ip_addr"
    fi
elif [[ $state -eq 3 ]]; then
    if [[ -n "$ip_addr" ]]; then
        output+=" $ip_addr"
    fi
fi

echo "$output  "