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

# ----------------------------------------------------------------
# Data Gathering
# ----------------------------------------------------------------
# Get the active interface type and profile name
DATA=$(nmcli -t -f TYPE,CONNECTION device | grep -E '^(wifi|ethernet):' | head -n 1)
IFACE_TYPE=$(echo "$DATA" | cut -d':' -f1)
CONN_NAME=$(echo "$DATA" | cut -d':' -f2)

# ----------------------------------------------------------------
# Icon Section
# ----------------------------------------------------------------
if $show_icon; then
    case "$IFACE_TYPE" in
        ethernet)
            output+=" " # Wired/Ethernet icon
            ;;
        wifi)
            # Query the current Wi-Fi network signal strength (0-100)
            SIGNAL=$(nmcli -t -f IN-USE,SIGNAL dev wifi | awk -F: '$1 == "*" {print $2; exit}')
            
            # Fallback if signal query returns blank
            if [[ -z "$SIGNAL" ]]; then
                output+="󰣻 " # Wi-Fi disconnected / searching
            elif (( SIGNAL > 75 )); then
                output+="󰣺 " # Excellent Signal (4 bars)
            elif (( SIGNAL > 50 )); then
                output+="󰣸 " # Good Signal (3 bars)
            elif (( SIGNAL > 25 )); then
                output+="󰣶 " # Fair Signal (2 bars)
            else
                output+="󰣴 " # Weak Signal (1 bar)
            fi
            ;;
        *)
            output+="󰣽 " # Global Disconnected Icon
            ;;
    esac
fi

# ----------------------------------------------------------------
# Network Name Section
# ----------------------------------------------------------------
if $show_network; then
    case "$IFACE_TYPE" in
        wifi)     output+="$CONN_NAME" ;;
        ethernet) output+="Ethernet" ;;
        *)        output+="Disconnected" ;;
    esac
fi

# ----------------------------------------------------------------
# IP Address Section
# ----------------------------------------------------------------
if $show_ip; then
    IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    
    if [[ -n "$IP_ADDR" ]]; then
        # Add a spacing separator if icon or network name text was already added
        [[ -n "$output" ]] && output+=" | "
        output+="$IP_ADDR"
    fi
fi

# Trim any remaining terminal spaces and output a single clean line
echo "$output" | xargs