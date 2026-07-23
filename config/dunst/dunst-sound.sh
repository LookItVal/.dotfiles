#!/bin/zsh

# Dunst exposes variables to scripts:
# $DUNST_SUMMARY -> Title of the notification
# $DUNST_URGENCY -> LOW, NORMAL, or CRITICAL

SOUND_DIR="$HOME/.config/dunst/sounds"

# Handle custom notification types first
case "$DUNST_SUMMARY" in
    *"Volume"*)
        # Subtle click or audio feedback
        paplay "$SOUND_DIR/volume.wav" 2>/dev/null &
        exit 0
        ;;
    *"Brightness"*)
        # Discrete pop
        paplay "$SOUND_DIR/volume.wav" 2>/dev/null &
        exit 0
        ;;
esac

# Fallback by Urgency level
case "$DUNST_URGENCY" in
    "LOW")
        paplay "$SOUND_DIR/pop.wav" 2>/dev/null &
        ;;
    "NORMAL")
        paplay "$SOUND_DIR/message.wav" 2>/dev/null &
        ;;
    "CRITICAL")
        paplay "$SOUND_DIR/bubbles.wav" 2>/dev/null &
        ;;
esac