#!/bin/zsh

STATE_FILE="$HOME/.config/i3blocks/.toggle_cpu_usage"
button="${BLOCK_BUTTON:-$button}"

# 0: icon only, 1: icon + total usage, 2: icon + total usage + active cores
state=1
if [[ -f "$STATE_FILE" ]]; then
    saved_state=$(<"$STATE_FILE")
    if [[ "$saved_state" =~ '^[0-2]$' ]]; then
        state=$saved_state
    fi
else
    print -r -- "$state" >| "$STATE_FILE"
fi

if [[ -n "$button" ]]; then
    state=$(( (state + 1) % 3 ))
    print -r -- "$state" >| "$STATE_FILE"
fi

snapshot1=$(grep '^cpu' /proc/stat)
sleep 0.2
snapshot2=$(grep '^cpu' /proc/stat)

metrics=$(printf "%s\n---\n%s\n" "$snapshot1" "$snapshot2" | awk '
BEGIN { phase=1; overall=0; active=0; cores=0 }
/^---$/ { phase=2; next }
phase==1 && $1 ~ /^cpu/ {
    key=$1
    for (i=2; i<=NF; i++) {
        prev[key, i]=$i
    }
    next
}
phase==2 && $1 ~ /^cpu/ {
    key=$1
    total=0
    for (i=2; i<=NF; i++) {
        total += ($i - prev[key, i])
    }
    idle = (($5 - prev[key, 5]) + ($6 - prev[key, 6]))
    usage = (total > 0) ? ((total - idle) * 100 / total) : 0

    if (key == "cpu") {
        overall = usage
    } else {
        cores++
        if (usage > 50) {
            active++
        }
    }
}
END {
    printf "%.1f %d %d", overall, active, cores
}
')

parts=(${=metrics})
overall="${parts[1]:-0.0}"
active_cores="${parts[2]:-0}"
total_cores="${parts[3]:-1}"

icon=" "
output="$icon"

if [[ $state -eq 1 ]]; then
    output+=" ${overall}%"
elif [[ $state -eq 2 ]]; then
    output+=" ${overall}% ${active_cores}/${total_cores}c"
fi

echo " $output"