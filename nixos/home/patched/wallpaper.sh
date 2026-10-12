#!/usr/bin/env zsh

# Set environment variables
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

WALLPAPER_BASE="${1:-$HOME/.local/share/wallpapers}"
LANDSCAPE_DIR="$WALLPAPER_BASE/landscape"
PORTRAIT_DIR="$WALLPAPER_BASE/portrait"

# For each connected output, read its actual (post-rotation) geometry from
# xrandr and pick a wallpaper from the matching orientation pool. This way
# a rotated monitor always gets a portrait image regardless of which output
# name or autorandr profile is active.
wallpapers=()
while IFS= read -r line; do
    geometry=$(echo "$line" | grep -oP '\d+x\d+(?=\+)')
    [[ -z "$geometry" ]] && continue

    width="${geometry%x*}"
    height="${geometry#*x}"

    if (( height > width )); then
        pool="$PORTRAIT_DIR"
    else
        pool="$LANDSCAPE_DIR"
    fi

    wallpapers+=("$pool/$(ls $pool | shuf -n 1)")
done < <(xrandr --query | grep " connected")

feh --bg-fill "${wallpapers[@]}"
