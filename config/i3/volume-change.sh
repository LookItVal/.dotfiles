#!/bin/zsh

# Handle volume adjustments using pactl
case "$1" in
    up)
        pactl set-sink-mute @DEFAULT_SINK@ 0
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        pactl set-sink-mute @DEFAULT_SINK@ 0
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute}"
        exit 1
        ;;
esac

# Trigger i3status refresh if active
pkill -RTMIN+10 i3status 2>/dev/null || true

# Check if muted
is_muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

if [[ "$is_muted" == "yes" ]]; then
    # Keep the progress bar active, but set it to 0% with the mute icon
    notify-send \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:0 \
        "  Volume" \
        "Muted" \
        -t 1000
else
    # Parse volume percentage from pactl output
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -n1)

    # Pick icon based on volume level
    if [[ "$vol" -eq 0 ]]; then
        icon=""
    elif [[ "$vol" -lt 50 ]]; then
        icon=""
    else
        icon=""
    fi

    notify-send \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:"$vol" \
        "${icon}  Volume" \
        "${vol}%" \
        -t 1000
fi