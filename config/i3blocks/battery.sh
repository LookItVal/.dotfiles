#!/usr/bin/env bash

# --- Argument Parsing ---
SHOW_PERCENT=false

for arg in "$@"; do
    case "$arg" in
        -p|--percent)
            SHOW_PERCENT=true
            shift
            ;;
    esac
done

# --- 1. Check for Battery Presence ---
# Finds the first BAT directory under /sys/class/power_supply/
BAT_PATH=$(find /sys/class/power_supply/ -maxdepth 1 -name "BAT*" | head -n 1)

# Exit silently (outputs nothing) if no battery exists
if [[ -z "$BAT_PATH" || ! -d "$BAT_PATH" ]]; then
    exit 0
fi

# --- 2. Read Battery State & Capacity ---
CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null)
STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)

# Fallback check if reading capacity failed
if [[ -z "$CAPACITY" ]]; then
    exit 0
fi

# --- 3. Determine Icon ---
ICON=""

if [[ "$STATUS" == "Charging" ]]; then
    # Assign icons based on remaining percentage
    if [[ "$CAPACITY" -ge 90 ]]; then
        ICON="󰂅" # Full / High
    elif [[ "$CAPACITY" -ge 80 ]]; then
        ICON="󰂋"
    elif [[ "$CAPACITY" -ge 70 ]]; then
        ICON="󰂊"
    elif [[ "$CAPACITY" -ge 60 ]]; then
        ICON="󰢞"
    elif [[ "$CAPACITY" -ge 50 ]]; then
        ICON="󰂉"
    elif [[ "$CAPACITY" -ge 40 ]]; then
        ICON="󰢝"
    elif [[ "$CAPACITY" -ge 30 ]]; then
        ICON="󰂈"
    elif [[ "$CAPACITY" -ge 20 ]]; then
        ICON="󰂇"
    elif [[ "$CAPACITY" -ge 10 ]]; then
        ICON="󰂆"
    else
        ICON="󰢜" # Critical
    fi
else
    # Assign icons based on remaining percentage
    if [[ "$CAPACITY" -ge 90 ]]; then
        ICON="󰁹" # Full / High
    elif [[ "$CAPACITY" -ge 80 ]]; then
        ICON="󰂂"
    elif [[ "$CAPACITY" -ge 70 ]]; then
        ICON="󰂁"
    elif [[ "$CAPACITY" -ge 60 ]]; then
        ICON="󰂀"
    elif [[ "$CAPACITY" -ge 50 ]]; then
        ICON="󰁿"
    elif [[ "$CAPACITY" -ge 40 ]]; then
        ICON="󰁾"
    elif [[ "$CAPACITY" -ge 30 ]]; then
        ICON="󰁽"
    elif [[ "$CAPACITY" -ge 20 ]]; then
        ICON="󰁼"
    elif [[ "$CAPACITY" -ge 10 ]]; then
        ICON="󰁻"
    else
        ICON="󰁺" # Critical
    fi
fi

# --- 4. Format Output ---
if [[ "$SHOW_PERCENT" == true ]]; then
    echo " $ICON ${CAPACITY}%"
else
    echo " $ICON"
fi