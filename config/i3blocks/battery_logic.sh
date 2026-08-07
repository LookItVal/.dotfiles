#!/usr/bin/env bash

set -u

STATE_DIR="$HOME/.config/i3blocks"
HISTORY_FILE="$STATE_DIR/.battery_history.csv"
HISTORY_WINDOW_SEC=14400
ROLLING_POWER_WINDOW_SEC=600
ROLLING_POWER_MIN_SAMPLES=12
ROLL_DISCHARGE_FILE="$STATE_DIR/.battery_power_window_discharge.csv"
ROLL_CHARGE_FILE="$STATE_DIR/.battery_power_window_charge.csv"
PRUNE_STAMP_FILE="$STATE_DIR/.battery_history_prune_ts"
HISTORY_PRUNE_EVERY_SEC=60

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

find_battery_path() {
    local bat_path
    for bat_path in /sys/class/power_supply/BAT*; do
        if [[ -d "$bat_path" ]]; then
            printf "%s\n" "$bat_path"
            return
        fi
    done
}

read_int_file() {
    local path="$1"
    if [[ -r "$path" ]]; then
        local value
        IFS= read -r value < "$path"
        printf "%s" "$value"
    fi
}

resolve_energy_uwh() {
    local bat_path="$1"
    local energy_now=""
    local energy_full=""

    energy_now=$(read_int_file "$bat_path/energy_now")
    energy_full=$(read_int_file "$bat_path/energy_full")
    if [[ -n "$energy_now" && -n "$energy_full" ]]; then
        printf "%s|%s\n" "$energy_now" "$energy_full"
        return
    fi

    local charge_now=""
    local charge_full=""
    local voltage_now=""
    charge_now=$(read_int_file "$bat_path/charge_now")
    charge_full=$(read_int_file "$bat_path/charge_full")
    voltage_now=$(read_int_file "$bat_path/voltage_now")

    if [[ -n "$charge_now" && -n "$charge_full" && -n "$voltage_now" && "$voltage_now" -gt 0 ]]; then
        local converted_now converted_full
        converted_now=$(awk -v c="$charge_now" -v v="$voltage_now" 'BEGIN { printf "%.0f", (c * v) / 1000000 }')
        converted_full=$(awk -v c="$charge_full" -v v="$voltage_now" 'BEGIN { printf "%.0f", (c * v) / 1000000 }')
        printf "%s|%s\n" "$converted_now" "$converted_full"
        return
    fi

    printf "|\n"
}

resolve_power_uw() {
    local bat_path="$1"
    local power_now=""
    power_now=$(read_int_file "$bat_path/power_now")
    if [[ -n "$power_now" && "$power_now" -gt 0 ]]; then
        printf "%s\n" "$power_now"
        return
    fi

    local current_now=""
    local voltage_now=""
    current_now=$(read_int_file "$bat_path/current_now")
    voltage_now=$(read_int_file "$bat_path/voltage_now")
    if [[ -n "$current_now" && -n "$voltage_now" && "$current_now" -gt 0 && "$voltage_now" -gt 0 ]]; then
        awk -v i="$current_now" -v v="$voltage_now" 'BEGIN { printf "%.0f\n", (i * v) / 1000000 }'
        return
    fi

    printf "\n"
}

battery_icon() {
    local status="$1"
    local capacity="$2"

    if [[ "$status" == "Charging" ]]; then
        if [[ "$capacity" -ge 90 ]]; then echo "󰂅"; return; fi
        if [[ "$capacity" -ge 80 ]]; then echo "󰂋"; return; fi
        if [[ "$capacity" -ge 70 ]]; then echo "󰂊"; return; fi
        if [[ "$capacity" -ge 60 ]]; then echo "󰢞"; return; fi
        if [[ "$capacity" -ge 50 ]]; then echo "󰂉"; return; fi
        if [[ "$capacity" -ge 40 ]]; then echo "󰢝"; return; fi
        if [[ "$capacity" -ge 30 ]]; then echo "󰂈"; return; fi
        if [[ "$capacity" -ge 20 ]]; then echo "󰂇"; return; fi
        if [[ "$capacity" -ge 10 ]]; then echo "󰂆"; return; fi
        echo "󰢜"
        return
    fi

    if [[ "$capacity" -ge 90 ]]; then echo "󰁹"; return; fi
    if [[ "$capacity" -ge 80 ]]; then echo "󰂂"; return; fi
    if [[ "$capacity" -ge 70 ]]; then echo "󰂁"; return; fi
    if [[ "$capacity" -ge 60 ]]; then echo "󰂀"; return; fi
    if [[ "$capacity" -ge 50 ]]; then echo "󰁿"; return; fi
    if [[ "$capacity" -ge 40 ]]; then echo "󰁾"; return; fi
    if [[ "$capacity" -ge 30 ]]; then echo "󰁽"; return; fi
    if [[ "$capacity" -ge 20 ]]; then echo "󰁼"; return; fi
    if [[ "$capacity" -ge 10 ]]; then echo "󰁻"; return; fi
    echo "󰁺"
}

append_and_prune_history() {
    local ts="$1"
    local status="$2"
    local capacity="$3"
    local energy_uwh="$4"
    local power_uw="$5"

    ensure_state_dir
    touch "$HISTORY_FILE"
    printf "%s,%s,%s,%s,%s\n" "$ts" "$status" "$capacity" "$energy_uwh" "$power_uw" >> "$HISTORY_FILE"

    local last_prune_ts=0
    if [[ -r "$PRUNE_STAMP_FILE" ]]; then
        last_prune_ts=$(cat "$PRUNE_STAMP_FILE" 2>/dev/null)
    fi

    if [[ ! "$last_prune_ts" =~ ^[0-9]+$ ]]; then
        last_prune_ts=0
    fi

    if (( ts - last_prune_ts >= HISTORY_PRUNE_EVERY_SEC )); then
        local cutoff=$((ts - HISTORY_WINDOW_SEC))
        awk -F, -v cutoff="$cutoff" 'NF >= 5 && $1 >= cutoff' "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
        printf "%s\n" "$ts" > "$PRUNE_STAMP_FILE"
    fi
}

format_duration() {
    local seconds="$1"
    if [[ -z "$seconds" || "$seconds" -le 0 ]]; then
        printf "\n"
        return
    fi

    local hours=$((seconds / 3600))
    local mins=$(((seconds % 3600) / 60))
    if [[ "$hours" -gt 0 ]]; then
        printf "%dh%02dm\n" "$hours" "$mins"
    else
        printf "%dm\n" "$mins"
    fi
}

eta_from_history_discharging() {
    local energy_now="$1"
    local now_ts="$2"

    if [[ ! -s "$HISTORY_FILE" ]]; then
        printf "\n"
        return
    fi

    awk -F, -v now="$now_ts" -v e_now="$energy_now" '
    BEGIN { first_t=0; first_e=0; last_t=0; last_e=0 }
    $2 == "Discharging" && $4 ~ /^[0-9]+$/ {
        t=$1+0
        e=$4+0
        if (now - t > 7200) next
        if (first_t == 0 || t < first_t) { first_t=t; first_e=e }
        if (t > last_t) { last_t=t; last_e=e }
    }
    END {
        if (first_t == 0 || last_t == 0 || last_t <= first_t) {
            print ""
            exit
        }
        dt=last_t-first_t
        de=first_e-last_e
        if (dt < 600 || de <= 0) {
            print ""
            exit
        }
        rate=de/dt
        if (rate <= 0) {
            print ""
            exit
        }
        eta=e_now/rate
        if (eta < 0) eta=0
        printf "%.0f", eta
    }' "$HISTORY_FILE"
}

update_power_window_and_average() {
    local status="$1"
    local power_uw="$2"
    local now_ts="$3"
    local window_file=""

    if [[ "$status" == "Discharging" ]]; then
        window_file="$ROLL_DISCHARGE_FILE"
    elif [[ "$status" == "Charging" ]]; then
        window_file="$ROLL_CHARGE_FILE"
    else
        printf "\n"
        return
    fi

    ensure_state_dir
    touch "$window_file"

    if [[ -n "$power_uw" && "$power_uw" -gt 0 ]]; then
        printf "%s,%s\n" "$now_ts" "$power_uw" >> "$window_file"
    fi

    local cutoff=$((now_ts - ROLLING_POWER_WINDOW_SEC))
    awk -F, -v cutoff="$cutoff" '
    NF >= 2 {
        t=$1+0
        p=$2+0
        if (t >= cutoff && p > 0) {
            print $0
        }
    }' "$window_file" > "${window_file}.tmp" && mv "${window_file}.tmp" "$window_file"

    if [[ ! -s "$window_file" ]]; then
        printf "\n"
        return
    fi

    awk -F, -v min_samples="$ROLLING_POWER_MIN_SAMPLES" '
    NF >= 2 {
        p=$2+0
        if (p > 0) {
            sum += p
            count += 1
        }
    }
    END {
        if (count >= min_samples) {
            printf "%.0f", sum / count
        } else {
            print ""
        }
    }' "$window_file"
}

predict_eta() {
    local status="$1"
    local energy_now="$2"
    local energy_full="$3"
    local power_uw="$4"
    local now_ts="$5"

    local smoothed_power_uw=""
    local effective_power_uw=""
    local eta_sec=""

    smoothed_power_uw=$(update_power_window_and_average "$status" "$power_uw" "$now_ts")
    if [[ -n "$smoothed_power_uw" && "$smoothed_power_uw" -gt 0 ]]; then
        effective_power_uw="$smoothed_power_uw"
    else
        effective_power_uw="$power_uw"
    fi

    if [[ "$status" == "Discharging" ]]; then
        if [[ -n "$effective_power_uw" && "$effective_power_uw" -gt 0 && -n "$energy_now" && "$energy_now" -gt 0 ]]; then
            eta_sec=$(awk -v e="$energy_now" -v p="$effective_power_uw" 'BEGIN { printf "%.0f", (e * 3600) / p }')
        else
            eta_sec=$(eta_from_history_discharging "$energy_now" "$now_ts")
        fi
    elif [[ "$status" == "Charging" ]]; then
        if [[ -n "$effective_power_uw" && "$effective_power_uw" -gt 0 && -n "$energy_now" && -n "$energy_full" && "$energy_full" -gt "$energy_now" ]]; then
            eta_sec=$(awk -v e="$energy_now" -v f="$energy_full" -v p="$effective_power_uw" 'BEGIN { printf "%.0f", ((f - e) * 3600) / p }')
        fi
    fi

    local eta_text
    eta_text=$(format_duration "$eta_sec")
    printf "%s|%s\n" "$eta_text" "$eta_sec"
}

main() {
    ensure_state_dir

    local bat_path
    bat_path=$(find_battery_path)
    if [[ -z "$bat_path" || ! -d "$bat_path" ]]; then
        printf "\n"
        exit 0
    fi

    local capacity status
    capacity=$(read_int_file "$bat_path/capacity")
    status=$(read_int_file "$bat_path/status")
    if [[ -z "$capacity" || -z "$status" ]]; then
        printf "\n"
        exit 0
    fi

    local energy_pair energy_now energy_full power_uw now_ts
    energy_pair=$(resolve_energy_uwh "$bat_path")
    IFS='|' read -r energy_now energy_full <<< "$energy_pair"
    power_uw=$(resolve_power_uw "$bat_path")
    now_ts=$(date +%s)

    append_and_prune_history "$now_ts" "$status" "$capacity" "$energy_now" "$power_uw"

    local eta_payload eta eta_sec icon
    eta_payload=$(predict_eta "$status" "$energy_now" "$energy_full" "$power_uw" "$now_ts")
    IFS='|' read -r eta eta_sec <<< "$eta_payload"
    icon=$(battery_icon "$status" "$capacity")

    # --- Low Battery Notification Guard ---
    local NOTIFY_FLAG_FILE="$STATE_DIR/.battery_notified_low"

    if [[ "$status" == "Discharging" && "$capacity" -lt 15 ]]; then
        # Only notify if we haven't already sent a alert for this discharge cycle
        if [[ ! -f "$NOTIFY_FLAG_FILE" ]]; then
            notify-send -u critical \
                -h string:x-dunst-stack-tag:battery_low \
                "󰂃 Low Battery Warning" \
                "Battery is at ${capacity}%. Plug in your charger!" \
                -t 5000
            
            # Create flag so it doesn't trigger again every second
            touch "$NOTIFY_FLAG_FILE"
        fi
    else
        # Reset the flag whenever charging or back above 15%
        rm -f "$NOTIFY_FLAG_FILE" 2>/dev/null
    fi

    printf "%s|%s|%s|%s|%s\n" "$icon" "$capacity" "$status" "$eta" "$eta_sec"
}

main "$@"
