#!/usr/bin/env bash
# Dunst notifications when Claude (work + personal) / Cursor / Copilot usage crosses a threshold.
#   ≥50%              → normal notification
#   ≥85, 90, 95, 100% → critical notification (sticky; red frame + bubbles sound via dunstrc)
# Each threshold fires once per billing window: the state is keyed on the reset time, so it re-arms
# automatically when the window rolls over. Runs detached from statusline.sh; safe to run by hand too.
#   usage-alerts.sh --test   → send one sample normal + one sample critical notification
export LC_ALL=C.UTF-8
HERE=$(dirname "$(readlink -f "$0")")
DIR=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
STATE=$DIR/alerts.state          # lines: "<metric> <reset-key> <highest-threshold-notified>"
THRESHOLDS=(50 85 90 95 100)
CRITICAL_FROM=85

notify() {  # metric-id urgency summary body
  # stable per-metric id so a newer alert replaces the older one instead of stacking
  local id=$(( 7700 + $(cksum <<<"$1" | cut -d' ' -f1) % 100 ))
  dunstify -a "Usage" -u "$2" -r "$id" -i dialog-information "$3" "$4" 2>/dev/null ||
    notify-send -a "Usage" -u "$2" "$3" "$4"
}

if [[ $1 == --test ]]; then
  notify test-normal normal "Claude weekly usage 52%" "Crossed 50% · resets in 2d7h"
  notify test-crit critical "Cursor other models 90%" "Crossed 90% · resets in 27d"
  exit 0
fi

mkdir -p "$DIR"
exec 9>"$STATE.lock"; flock -n 9 || exit 0     # status line can fire this often; one at a time
touch "$STATE"

until_reset() {
  local t=$1 d
  [[ -z $t || $t == null ]] && return
  [[ $t =~ ^[0-9]+$ ]] || t=$(date -d "$t" +%s 2>/dev/null) || return
  d=$(( t - $(date +%s) )); (( d < 0 )) && d=0
  if (( d >= 86400 )); then printf 'resets in %dd%dh' $((d/86400)) $((d%86400/3600))
  elif (( d >= 3600 )); then printf 'resets in %dh%dm' $((d/3600)) $((d%3600/60))
  else printf 'resets in %dm' $((d/60)); fi
}

# metric-id <TAB> label <TAB> percent <TAB> reset
metrics() {
  "$HERE/claude-usage.sh" >/dev/null 2>&1   # refresh both Claude accounts from the API (2-min TTL)
  [[ -f $DIR/claude-usage.json ]] && jq -r '
      ["claude-session", "Claude session usage", .session.used_percentage, .session.resets_at],
      ["claude-weekly",  "Claude weekly usage",  .weekly.used_percentage,  .weekly.resets_at]
      | select(.[2] != null) | map(tostring) | @tsv' "$DIR/claude-usage.json" 2>/dev/null
  [[ -f $DIR/claude-usage-personal.json ]] && jq -r '
      ["personal-session", "Claude personal session usage", .session.used_percentage, .session.resets_at],
      ["personal-weekly",  "Claude personal weekly usage",  .weekly.used_percentage,  .weekly.resets_at]
      | select(.[2] != null) | map(tostring) | @tsv' "$DIR/claude-usage-personal.json" 2>/dev/null
  "$HERE/cursor-usage.sh" 2>/dev/null | jq -r '
      ["cursor-auto", "Cursor models usage", .individualUsage.plan.autoPercentUsed, .billingCycleEnd],
      ["cursor-api",  "Cursor other models", .individualUsage.plan.apiPercentUsed,  .billingCycleEnd]
      | select(.[2] != null) | map(tostring) | @tsv' 2>/dev/null
  "$HERE/copilot-usage.sh" 2>/dev/null | jq -r '.quota_snapshots.premium_interactions as $q
      | select($q and ($q.unlimited | not))
      | ["copilot-premium", "Copilot premium requests", 100 - $q.percent_remaining, .quota_reset_date]
      | map(tostring) | @tsv' 2>/dev/null
}

while IFS=$'\t' read -r id label pct reset; do
  [[ -z $id || -z $pct ]] && continue
  p=$(printf '%.0f' "$pct")
  # Round the reset key to the hour so small drifts in resets_at don't re-arm alerts
  key=$reset; [[ $key =~ ^[0-9]+$ ]] && key=$(( key / 3600 ))
  [[ -z $key ]] && key=none

  hit=0
  for t in "${THRESHOLDS[@]}"; do (( p >= t )) && hit=$t; done

  read -r _ old_key old_hit < <(grep -m1 "^$id " "$STATE")
  [[ $old_key != "$key" ]] && old_hit=0            # new billing window → re-arm
  old_hit=${old_hit:-0}

  if (( hit > old_hit )); then
    urgency=normal; (( hit >= CRITICAL_FROM )) && urgency=critical
    if (( hit >= 100 )); then body="Limit reached"; else body="Crossed $hit%"; fi
    r=$(until_reset "$reset"); [[ -n $r ]] && body+=" · $r"
    notify "$id" "$urgency" "$label $p%" "$body"
  fi
  # Record the current level (also lowers it if usage dropped, e.g. after a reset)
  { grep -v "^$id " "$STATE"; echo "$id $key $hit"; } >| "$STATE.tmp" && mv -f "$STATE.tmp" "$STATE"
done < <(metrics)
exit 0
