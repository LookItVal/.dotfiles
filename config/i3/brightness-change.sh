#!/bin/zsh

# Adjust brightness based on the first argument ("up" or "down")
case "$1" in
    up)
        brightnessctl set +5%
        ;;
    down)
        brightnessctl set 5%-
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac

# Get current brightness percentage cleanly
bright=$(brightnessctl -m | cut -d, -f4 | tr -d %)

# Send stacked notification to Dunst
notify-send \
    -h string:x-dunst-stack-tag:brightness \
    -h int:value:"$bright" \
    "󰃠  Brightness" \
    "${bright}%" \
    -t 1000