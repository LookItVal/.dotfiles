#!/bin/zsh

STATE_DIR="$HOME/.config/i3blocks"
CACHE_FILE="$STATE_DIR/.gpu_stats_cache"
LOCK_DIR="$STATE_DIR/.gpu_stats_lock"
CACHE_TTL=2

mkdir -p "$STATE_DIR"

now_ts=$(date +%s)

emit_cache() {
    local cached_ts cached_payload
    if [[ -r "$CACHE_FILE" ]]; then
        IFS='|' read -r cached_ts cached_payload < "$CACHE_FILE"
        if [[ "$cached_ts" =~ '^[0-9]+$' ]] && (( now_ts - cached_ts <= CACHE_TTL )) && [[ -n "$cached_payload" ]]; then
            printf "%s\n" "$cached_payload"
            return 0
        fi
    fi
    return 1
}

if emit_cache; then
    exit 0
fi

# Light-weight lock so gpu_usage/gpu_temperature share one nvidia-smi call.
acquired_lock=false
if mkdir "$LOCK_DIR" 2>/dev/null; then
    acquired_lock=true
fi

if ! $acquired_lock; then
    # Another block is refreshing; if it just wrote cache, use it.
    if emit_cache; then
        exit 0
    fi
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    payload="NA|0|0|0"
else
    query_out=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [[ -z "$query_out" ]]; then
        payload="NA|0|0|0"
    else
        payload=$(printf "%s" "$query_out" | awk -F', *' '{printf "%d|%d|%d|%d", $1 + 0, $2 + 0, $3 + 0, $4 + 0}')
    fi
fi

printf "%s|%s\n" "$now_ts" "$payload" >| "$CACHE_FILE"
printf "%s\n" "$payload"

if $acquired_lock; then
    rmdir "$LOCK_DIR" 2>/dev/null
fi
