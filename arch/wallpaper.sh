#!/bin/zsh

# Set environment variables
export DISPLAY=:0
export XAUTHORITY=/home/val/.Xauthority

# Select a random wallpaper from the wallpapers directory
wallpaper=$(ls /etc/systemd/system/wallpapers | shuf -n 1)
# Set the wallpaper
feh --bg-fill /etc/systemd/system/wallpapers/$wallpaper