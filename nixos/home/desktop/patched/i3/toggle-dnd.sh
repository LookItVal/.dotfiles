#!/usr/bin/env zsh

# Toggle dunst pause. Every press flips a desired-state file (under a lock, so spamming
# is safe) and updates the SAME popup (stack tag) to show the new state.
# Dunst hides popups while paused, so for "On" the real pause is applied after the popup
# has been visible; a token makes sure only the latest press gets to apply it.

dir="${XDG_RUNTIME_DIR:-/tmp}"
state="$dir/dnd-state"
token="$dir/dnd-token"
icons="$HOME/.config/dunst/icons"

exec 9>"$dir/dnd.lock"
flock 9

[[ -f $state ]] && cur="$(<$state)"
if [[ "$cur" == "on" ]]; then
    new=off
else
    new=on
fi
print -r -- "$new" >"$state"
my=$RANDOM$RANDOM
print -r -- "$my" >"$token"

# Always unpause first so the popup can actually be shown / replaced
dunstctl set-pause-level 0

if [[ "$new" == "on" ]]; then
    notify-send -a DND -i "$icons/dnd-on.png" -h string:x-dunst-stack-tag:dnd \
        "Do Not Disturb: ON" "Notifications are paused" -t 1500
    (
        sleep 1.6
        flock 9
        [[ "$(<$token)" == "$my" ]] && dunstctl set-pause-level 50
    ) 9>"$dir/dnd.lock" &!
else
    notify-send -a DND -i "$icons/dnd-off.png" -h string:x-dunst-stack-tag:dnd \
        "Do Not Disturb: OFF" "Notifications are on" -t 1500
fi
