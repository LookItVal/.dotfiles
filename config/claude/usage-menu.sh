#!/usr/bin/env bash
# Rofi popup with Claude (work + personal), Cursor and Copilot usage. Enter on a row opens that service's usage page.
# Colors come from statusline.sh's USAGE_STOPS gradient so everything matches.
export LC_ALL=C.UTF-8
HERE=$(dirname "$(readlink -f "$0")")
DIR=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
src=$HERE/statusline.sh

eval "$(grep -E '^[A-Z]+="[0-9]+;[0-9]+;[0-9]+"' "$src")"
eval "$(sed -n '/^USAGE_STOPS=(/,/^)/p' "$src")"
eval "$(sed -n '/^usage_color() {/,/^}/p' "$src")"
hex() { local IFS=';'; read -r r g b <<<"$1"; printf '#%02x%02x%02x' "$r" "$g" "$b"; }

# Row = icon(1) + 2 + label(16) + 1 + bar + 1 + pct(4) + 2 + reset(8) = 35 + bar characters.
# The window is sized in ch (character widths), so the bar fills it exactly; tweak WIDTH_CH to taste.
WIDTH_CH=${USAGE_MENU_WIDTH:-84}
BAR_W=$(( WIDTH_CH - 35 - 6 ))   # 6ch ≈ window + row padding and border
# Every glyph below exists in FiraCode Nerd Font Mono, so each is exactly 1ch wide — glyphs the
# font lacks (▰ ▱ ↻) fall back to a wider font and push rows past the window edge.
# Fira Code progress-bar pieces: left / middle / right, empty and filled
PB_L0=$'\uEE00'; PB_M0=$'\uEE01'; PB_R0=$'\uEE02'
PB_L1=$'\uEE03'; PB_M1=$'\uEE04'; PB_R1=$'\uEE05'
I_RESET=$'\U000F0450'   # nf-md-refresh
DIM="#6e738d"; TXT="#cad3f5"

until_reset() {
  local t=$1 d
  [[ -z $t || $t == null ]] && { printf '%8s' ''; return; }
  [[ $t =~ ^[0-9]+$ ]] || t=$(date -d "$t" +%s 2>/dev/null) || { printf '%8s' ''; return; }
  d=$(( t - $(date +%s) )); (( d < 0 )) && d=0
  if (( d >= 86400 )); then printf "$I_RESET "'%2dd%02dh' $((d/86400)) $((d%86400/3600))
  elif (( d >= 3600 )); then printf "$I_RESET "'%2dh%02dm' $((d/3600)) $((d%3600/60))
  else printf "$I_RESET "'%5dm' $((d/60)); fi
}

row() {  # icon label pct reset
  local icon=$1 label=$2 pct=$3 reset=$4 p n i bar="" c
  p=$(printf '%.0f' "$pct"); (( p > 100 )) && p=100
  c=$(hex "$(usage_color "$p")")
  n=$(( (p * BAR_W + 50) / 100 )); (( n == 0 && p > 0 )) && n=1
  for (( i = 0; i < BAR_W; i++ )); do
    local f=0; (( i < n )) && f=1
    if   (( i == 0 ));         then [[ $f == 1 ]] && bar+=$PB_L1 || bar+=$PB_L0
    elif (( i == BAR_W - 1 )); then [[ $f == 1 ]] && bar+=$PB_R1 || bar+=$PB_R0
    else                            [[ $f == 1 ]] && bar+=$PB_M1 || bar+=$PB_M0; fi
  done
  printf '<span foreground="%s">%s</span>  %-16s <span foreground="%s">%s</span> <span foreground="%s" weight="bold">%4s</span>  <span foreground="%s">%s</span>\n' \
    "$c" "$icon" "$label" "$c" "$bar" "$c" "$p%" "$DIM" "$(until_reset "$reset")"
}

rows=() urls=() ages=()
ago() {  # epoch → "3m ago"
  local a=$(( $(date +%s) - $1 ))
  if (( a < 60 )); then echo "just now"; elif (( a < 3600 )); then echo "$(( a / 60 ))m ago"
  elif (( a < 86400 )); then echo "$(( a / 3600 ))h ago"; else echo "$(( a / 86400 ))d ago"; fi
}
claude_rows() {  # cache-file name-prefix
  [[ -f $1 ]] || return
  local s sr w wr up
  IFS=$'\t' read -r s sr w wr up < <(jq -r '[.session.used_percentage, .session.resets_at,
      .weekly.used_percentage, .weekly.resets_at, .updated] | map(tostring) | @tsv' "$1")
  [[ $s != null ]] && { rows+=("$(row $'\U000F051F' "$2 session" "$s" "$sr")"); urls+=(https://claude.ai/settings/usage); }
  [[ $w != null ]] && { rows+=("$(row $'\U000F00ED' "$2 weekly" "$w" "$wr")"); urls+=(https://claude.ai/settings/usage); }
  [[ $up != null ]] && ages+=("${3:-$2} $(ago "$up")")
}
# Pull fresh Claude numbers for both accounts first (≤5s, skipped if fetched in the last 2 min)
"$HERE/claude-usage.sh" >/dev/null 2>&1
claude_rows "$DIR/claude-usage.json" Claude work
claude_rows "$DIR/claude-usage-personal.json" Personal personal

if cu=$("$HERE/cursor-usage.sh" 2>/dev/null) && [[ -n $cu ]]; then
  IFS=$'\t' read -r ca cp ce < <(jq -r '[.individualUsage.plan.autoPercentUsed, .individualUsage.plan.apiPercentUsed,
      .billingCycleEnd] | map(tostring) | @tsv' <<<"$cu")
  [[ $ca != null ]] && { rows+=("$(row $'\U000F01BF' "Cursor models" "$ca" "$ce")"); urls+=(https://cursor.com/dashboard); }
  [[ $cp != null ]] && { rows+=("$(row $'\U000F01BF' "Other models" "$cp" "$ce")"); urls+=(https://cursor.com/dashboard); }
fi
if gu=$("$HERE/copilot-usage.sh" 2>/dev/null) && [[ -n $gu ]]; then
  IFS=$'\t' read -r gp ge < <(jq -r '.quota_snapshots.premium_interactions as $q
      | [(if $q and ($q.unlimited | not) then 100 - $q.percent_remaining else null end), .quota_reset_date]
      | map(tostring) | @tsv' <<<"$gu")
  [[ $gp != null ]] && { rows+=("$(row $'\U000F02A4' "Copilot premium" "$gp" "$ge")"); urls+=(https://github.com/settings/copilot/features); }
fi

if (( ${#rows[@]} == 0 )); then
  rofi -e "No usage data yet — open Claude Code once so the status line can record it."
  exit 0
fi

ago=""
(( ${#ages[@]} )) && ago="Claude updated $(IFS=,; echo "${ages[*]}" | sed 's/,/ · /g')"

# Look comes from ~/.config/rofi/config.rasi; only the popup-specific bits are set here.
theme="
*        { font: \"FiraCode Nerd Font Mono 12\"; }
window   { width: ${WIDTH_CH}ch; }
mainbox  { children: [ \"message\", \"listview\" ]; }
message  { border: 0 0 1px 0; border-color: #494d64; padding: 2px 0 10px 8px; margin: 0 0 6px 0; }
listview { border: 0; padding: 0; }
listview { lines: ${#rows[@]}; }
"
mesg="<span weight=\"bold\" size=\"large\" foreground=\"#c6a0f6\">󰚩  Usage</span>"
[[ -n $ago ]] && mesg+="   <span foreground=\"$DIM\" size=\"small\">$ago</span>"

idx=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -markup-rows -no-custom -no-show-icons -format i \
        -p "" -mesg "$mesg" -theme-str "$theme" 2>/dev/null) || exit 0
[[ -n $idx && -n ${urls[idx]} ]] && xdg-open "${urls[idx]}" >/dev/null 2>&1 &
exit 0
