#!/bin/zsh

# Dunst exposes variables to scripts:
# $DUNST_SUMMARY -> Title of the notification
# $DUNST_URGENCY -> LOW, NORMAL, or CRITICAL

SOUND_DIR="$HOME/.config/dunst/sounds"

# Notification volume (0-100, set from the rofi mixer). Same scale as pavucontrol sliders.
pct="$(<"${XDG_STATE_HOME:-$HOME/.local/state}/notif-volume" 2>/dev/null)"
[[ "$pct" == <-> ]] || pct=100

# Optional pinned output (set from the rofi mixer). Missing/disconnected sink -> follow default output.
dev=()
pin="$(<"${XDG_STATE_HOME:-$HOME/.local/state}/notif-sink" 2>/dev/null)"
if [[ -n "$pin" && "$pin" != auto ]] && pactl list short sinks | cut -f2 | grep -qxF -- "$pin"; then
    dev=(--device="$pin")
fi
play() { paplay "${dev[@]}" --volume=$(( 65536 * pct / 100 )) "$SOUND_DIR/$1" 2>/dev/null & }

# DND toggle popup (app name "DND") is always silent
[[ "$DUNST_APP_NAME" == "DND" ]] && exit 0

# While DND is on, only critical notifications make sound
if [[ "$DUNST_URGENCY" != "CRITICAL" ]] && (( $(dunstctl get-pause-level) > 0 )); then
    exit 0
fi

# Handle custom notification types first
case "$DUNST_SUMMARY" in
    *"Volume"*)
        # Subtle click or audio feedback
        play volume.wav
        exit 0
        ;;
    *"Brightness"*)
        # Discrete pop
        play volume.wav
        exit 0
        ;;
    *"Screenshot"*)
        # Camera shutter sound
        play camera-shutter.wav
        exit 0
        ;;
esac

# Fallback by Urgency level
case "$DUNST_URGENCY" in
    "LOW")
        play pop.wav
        ;;
    "NORMAL")
        play message.wav
        ;;
    "CRITICAL")
        play bubbles.wav
        ;;
esac