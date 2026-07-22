#!/bin/zsh

# Set environment variables
export DISPLAY=:0
export XAUTHORITY=/home/val/.Xauthority

WALLPAPER_DIR="/etc/systemd/system/wallpapers"

# Count connected/active monitors using xrandr
monitor_count=$(xrandr --query | grep -c " connected")

if [[ $monitor_count -ge 2 ]]; then
    # Pick 2 distinct wallpapers for multi-monitor setup
    wallpapers=($(ls $WALLPAPER_DIR | shuf -n 2))
    feh --bg-fill $WALLPAPER_DIR/$wallpapers[1] $WALLPAPER_DIR/$wallpapers[2]
else
    # Pick 1 wallpaper for single monitor mode
    wallpaper=$(ls $WALLPAPER_DIR | shuf -n 1)
    feh --bg-fill $WALLPAPER_DIR/$wallpaper
fi