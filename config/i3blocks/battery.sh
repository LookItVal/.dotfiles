#!/usr/bin/env bash

# --- Display Mode/Toggling Only ---
SHOW_PERCENT_DEFAULT=false
STATE_FILE="$HOME/.config/i3blocks/.toggle_battery"
BUTTON="${BLOCK_BUTTON:-$button}"
LOGIC_SCRIPT="$HOME/.config/i3blocks/battery_logic.sh"

for arg in "$@"; do
    case "$arg" in
        -p|--percent)
            SHOW_PERCENT_DEFAULT=true
            ;;
    esac
done

# 0: icon only, 1: icon + percent, 2: icon + percent + remaining time,
# 3: icon + percent + projected time-of-death
STATE=0
if [[ "$SHOW_PERCENT_DEFAULT" == true ]]; then
    STATE=1
fi

if [[ -f "$STATE_FILE" ]]; then
    SAVED_STATE=$(<"$STATE_FILE")
    if [[ "$SAVED_STATE" =~ ^[0-3]$ ]]; then
        STATE=$SAVED_STATE
    fi
else
    printf "%s\n" "$STATE" > "$STATE_FILE"
fi

if [[ -n "$BUTTON" ]]; then
    STATE=$(( (STATE + 1) % 4 ))
    printf "%s\n" "$STATE" > "$STATE_FILE"
fi

if [[ ! -x "$LOGIC_SCRIPT" ]]; then
    # Script might not have execute bit yet.
    if [[ ! -f "$LOGIC_SCRIPT" ]]; then
        exit 0
    fi
fi

logic_out=$(bash "$LOGIC_SCRIPT")
if [[ -z "$logic_out" ]]; then
    exit 0
fi

IFS='|' read -r ICON CAPACITY STATUS ETA ETA_SEC <<< "$logic_out"

projected_time=""
if [[ -n "$ETA_SEC" && "$ETA_SEC" =~ ^[0-9]+$ && "$ETA_SEC" -gt 0 ]]; then
    projected_time=$(date -d "@$(( $(date +%s) + ETA_SEC ))" "+%H:%M" 2>/dev/null)
fi

# --- Render Output ---
if [[ "$STATE" -eq 0 ]]; then
    echo " $ICON "
elif [[ "$STATE" -eq 1 ]]; then
    echo " $ICON ${CAPACITY}% "
elif [[ "$STATE" -eq 2 ]]; then
    if [[ -n "$ETA" ]]; then
        echo " $ICON ${CAPACITY}% ${ETA} "
    else
        echo " $ICON ${CAPACITY}% "
    fi
else
    if [[ -n "$projected_time" ]]; then
        if [[ "$STATUS" == "Discharging" ]]; then
            echo " $ICON ${CAPACITY}% 󱧦 ${projected_time} "
        elif [[ "$STATUS" == "Charging" ]]; then
            echo " $ICON ${CAPACITY}% 󱧥 ${projected_time} "
        else
            echo " $ICON ${CAPACITY}% ${projected_time} "
        fi
    else
        echo " $ICON ${CAPACITY}% "
    fi
fi