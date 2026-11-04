#!/usr/bin/env bash
# Print the status line's usage-color gradient, read straight from statusline.sh,
# so this stays accurate when the stops change.
export LC_ALL=C.UTF-8
here=$(dirname "$(readlink -f "$0")")
src="$here/statusline.sh"

# Pull the palette variables and the USAGE_STOPS table out of statusline.sh
eval "$(grep -E '^[A-Z]+="[0-9]+;[0-9]+;[0-9]+"' "$src")"
eval "$(sed -n '/^USAGE_STOPS=(/,/^)/p' "$src")"
eval "$(sed -n '/^usage_color() {/,/^}/p' "$src")"
eval "$(sed -n '/^model_color() {/,/^}/p' "$src")"

fg() { printf '\e[38;2;%sm' "$1"; }
bg() { printf '\e[48;2;%sm' "$1"; }
R=$'\e[0m'; B=$'\e[1m'; DIM=$(fg "128;135;162")
L=$''; Rc=$''; ON=$'▰'; OFF=$'▱'

# --- full 0–100 strip, one cell per percent
printf '\n %sUsage gradient%s  (context / session / weekly)\n\n   ' "$B" "$R"
for p in $(seq 0 100); do printf '%s█' "$(fg "$(usage_color "$p")")"; done
printf '%s\n   %s' "$R" "$DIM"
for p in $(seq 0 100); do (( p % 10 == 0 )) && printf '%-10s' "$p" ; done
printf '%s\n\n' "$R"

# --- one row per stop: swatch, range, share of the bar
n=${#USAGE_STOPS[@]}
for (( i = 0; i < n; i++ )); do
  from=${USAGE_STOPS[i]%%:*}; name=${USAGE_STOPS[i]#*:}
  if (( i + 1 < n )); then to=$(( ${USAGE_STOPS[i+1]%%:*} - 1 )); else to=100; fi
  span=$(( to - from + 1 ))
  c=${!name}
  range="$from–$to%"
  printf '   %s%s%s %-9s%s%s  %-8s ' "$(fg "$c")" "$L" "$(fg "36;39;58")$(bg "$c")" "${name,,}" "$R" "$(fg "$c")$Rc$R" "$range"
  # half scale: one cell per 2%, offset to where the color starts
  printf '%s%*s' "$(fg "$c")" $(( from / 2 )) ''
  for (( k = 0; k < (span + 1) / 2; k++ )); do printf '%s' "$ON"; done
  printf '%s %s(%d%%)%s\n' "$R" "$DIM" "$span" "$R"
done

# --- what a pill looks like at a few levels
printf '\n %sSample bars%s\n\n' "$B" "$R"
for p in 5 25 45 65 80 90 99; do
  c=$(usage_color "$p"); t=40; f=$(( (p * t + 50) / 100 )); bar=""
  for (( k = 0; k < t; k++ )); do (( k < f )) && bar+=$ON || bar+=$OFF; done
  printf '   %s%s%s context %s %3d%% %s%s%s\n' "$(fg "$c")" "$L" "$(fg "36;39;58")$(bg "$c")" "$bar" "$p" "$R" "$(fg "$c")$Rc" "$R"
done

# --- model colors
printf '\n %sModel colors%s\n\n' "$B" "$R"
for m in Haiku Sonnet Opus Fable Other; do
  c=$(model_color "$m")
  printf '   %s%s%s %-7s%s%s\n' "$(fg "$c")" "$L" "$(fg "36;39;58")$(bg "$c")" "$m" "$R" "$(fg "$c")$Rc$R"
done
echo
