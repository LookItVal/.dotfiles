#!/usr/bin/env bash
# Get cursor X and Y coordinates
eval $(xdotool getmouselocation --shell)

# Match cursor location against active xrandr monitor geometries
TARGET_INDEX=0
while read -r line; do
    idx=$(echo "$line" | awk '{print $1}' | tr -d ':')
    geom=$(echo "$line" | awk '{print $3}') # format: W/mmxH/mm+X+Y
    
    w=$(echo "$geom" | cut -d'/' -f1)
    h=$(echo "$geom" | cut -d'x' -f2 | cut -d'/' -f1)
    x=$(echo "$geom" | cut -d'+' -f2)
    y=$(echo "$geom" | cut -d'+' -f3)

    if (( X >= x && X < x + w && Y >= y && Y < y + h )); then
        TARGET_INDEX="$idx"
        break
    fi
done < <(xrandr --listactivemonitors | tail -n +2)

QT_QPA_PLATFORMTHEME=xdgdesktopportal flameshot screen -n "$TARGET_INDEX"
notify-send "Flameshot" "Screenshot taken on monitor $TARGET_INDEX"