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

default_iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}')

if [[ -z "$default_iface" ]]; then
    iface_type=""
elif [[ -d "/sys/class/net/$default_iface/wireless" ]]; then
    iface_type="wifi"
else
    iface_type="ethernet"
fi

case "$iface_type" in
    ethernet)
        icon=""
        network_name="Ethernet"
        ;;
    wifi)
        signal=$(awk -v iface="$default_iface" '$1 ~ iface":" { gsub(/\./, "", $3); print int(($3 + 0) * 100 / 70); exit }' /proc/net/wireless 2>/dev/null)
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
        if command -v iwgetid >/dev/null 2>&1; then
            network_name=$(iwgetid -r 2>/dev/null)
        fi
        [[ -z "$network_name" ]] && network_name="$default_iface"
        ;;
    *)
        icon="󰣽"
        network_name="Disconnected"
        ;;
esac

ip_addr=""
if [[ -n "$default_iface" ]]; then
    ip_addr=$(ip -4 -o addr show dev "$default_iface" 2>/dev/null | awk 'NR==1 {print $4}' | cut -d/ -f1)
fi

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