#!/usr/bin/env bash
# Claude Code status line — Catppuccin Macchiato.
#   Row 1: powerline  pwd → git → model   (pwd + git mirror the zsh eriner prompt)
#   Row 2: full-width context pill. Then 50/50 pairs: session | weekly, cursor | other (work)
#   or a copilot pill (personal / other CLAUDE_CONFIG_DIR profiles).
# Glyphs are written as escapes so editors/tools can't silently strip them.

export LC_ALL=C.UTF-8   # ${#str} counts characters, not bytes
input=$(cat)
[[ -n $CLAUDE_STATUSLINE_DEBUG ]] && printf '%s\n' "$input" >| "${TMPDIR:-/tmp}/claude-statusline.json"

# \x1f (unit separator) not tab: tab is IFS-whitespace, so empty fields would collapse and shift
IFS=$'\x1f' read -r dir model ctx week week_reset sess sess_reset width < <(
  jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // .model.id // "?"),
    (.context_window.used_percentage
      // (if .context_window.current_usage and .context_window.context_window_size then
            ((.context_window.current_usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
              * 100 / .context_window.context_window_size)
          else null end)
      // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.terminal.columns // .terminal_width // .columns // "")
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

# --- terminal width: payload → $COLUMNS → the tty of the nearest ancestor that has one → 80
term_width() {
  [[ $width =~ ^[0-9]+$ ]] && { echo "$width"; return; }
  [[ $COLUMNS =~ ^[0-9]+$ ]] && { echo "$COLUMNS"; return; }
  local pid=$$ tty cols
  for _ in 1 2 3 4 5 6; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || break
    [[ -z $pid || $pid == 1 ]] && break
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [[ -n $tty && $tty != '?' ]]; then
      cols=$(stty -F "/dev/$tty" size 2>/dev/null | cut -d' ' -f2)
      [[ $cols =~ ^[0-9]+$ ]] && { echo "$cols"; return; }
    fi
  done
  echo 80
}
W=$(term_width)

# Catppuccin Macchiato (same values as alacritty/catppuccin-macchiato.toml)
TEXT="36;39;58"
CYAN="139;213;202"; GREEN="166;218;149"; YELLOW="238;212;159"   # eriner PWD / CLEAN / DIRTY
PEACH="245;169;127"; RED="237;135;150"; MAUVE="198;160;246"; LAVENDER="183;189;248"
BLUE="138;173;244"; SAPPHIRE="125;196;228"; SKY="145;215;227"; TEAL="139;213;202"
MAROON="238;153;160"; PINK="245;189;230"

# Usage gradient, cool → hot. "from%:COLOR", ascending. statusline-colors.sh reads this table.
USAGE_STOPS=(
  0:LAVENDER 7:BLUE 14:SAPPHIRE 21:SKY 28:TEAL 35:GREEN
  50:YELLOW 70:PEACH 78:MAROON 85:RED 92:PINK 97:MAUVE
)

SEP=$''; BRANCH_ICON=$''; CAP_L=$''; CAP_R=$''; SEP_THIN=$''
I_MODEL=$'\U000F06A9'; I_CTX=$'\U000F035B'; I_SESS=$'\U000F051F'; I_WEEK=$'\U000F00ED'; I_CURSOR=$'\U000F01BF'; I_COPILOT=$'\U000F02A4'
CELL_ON=$'▰'; CELL_OFF=$'▱'   # ▰ ▱
fg() { printf '\e[38;2;%sm' "$1"; }
bg() { printf '\e[48;2;%sm' "$1"; }
R=$'\e[0m'

usage_color() {
  local p=${1%.*} stop name=LAVENDER
  for stop in "${USAGE_STOPS[@]}"; do (( p >= ${stop%%:*} )) && name=${stop#*:}; done
  echo "${!name}"
}

# Model color on the same scale, by how fast the model burns through limits
model_color() {
  case ${1,,} in
    *haiku*)  echo "$GREEN" ;;
    *sonnet*) echo "$YELLOW" ;;
    *opus*)   echo "$RED" ;;
    *fable*)  echo "$MAUVE" ;;
    *)        echo "$LAVENDER" ;;
  esac
}

# ---------- Row 1: powerline ----------
powerline() {
  local out="" prev="" seg color text
  for seg in "$@"; do
    color=${seg%%|*}; text=${seg#*|}
    if [[ -n $prev && $prev == "$color" ]]; then
      out+="$(fg "$TEXT")$(bg "$color")$SEP_THIN"     # same color both sides: thin divider
    elif [[ -n $prev ]]; then
      out+="$(fg "$prev")$(bg "$color")$SEP"
    fi
    out+="$(fg "$TEXT")$(bg "$color") $text "
    prev=$color
  done
  [[ -n $prev ]] && out+="$R$(fg "$prev")$SEP"
  printf '%s%s' "$out" "$R"
}

# pwd: zim prompt-pwd fish-style, dir-length 1 (~/.dotfiles/config/zsh → ~/.d/c/zsh)
short=${dir/#$HOME/\~}
if [[ $short == */* ]]; then
  head=${short%/*}; tail=${short##*/}
  IFS=/ read -ra parts <<<"$head"
  abbrev=""
  for p in "${parts[@]}"; do
    if [[ $p =~ ^(\.*.) ]]; then abbrev+="${BASH_REMATCH[1]}/"; else abbrev+="/"; fi
  done
  [[ -z $head ]] && abbrev="/"
  short="${abbrev}${tail}"
fi
segs=("$CYAN|$short")

# git: eriner format — branch / ➦ sha, (action), ± when tracked files changed; green clean, yellow dirty
if [[ -n $dir ]] && gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null); then
  [[ $gitdir == /* ]] || gitdir="$dir/$gitdir"
  g() { git -C "$dir" --no-optional-locks "$@" 2>/dev/null; }
  if branch=$(g symbolic-ref --short -q HEAD); then
    label="$BRANCH_ICON $branch"
  else
    label="➦ $(g rev-parse --short HEAD)"
  fi
  action=""
  if [[ -d $gitdir/rebase-merge || -d $gitdir/rebase-apply ]]; then action=rebase
  elif [[ -f $gitdir/MERGE_HEAD ]]; then action=merge
  elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then action=cherry-pick
  elif [[ -f $gitdir/REVERT_HEAD ]]; then action=revert
  elif [[ -f $gitdir/BISECT_LOG ]]; then action=bisect
  fi
  [[ -n $action ]] && label+=" ($action)"
  if g diff-index --no-ext-diff --quiet --cached HEAD && g diff-files --no-ext-diff --quiet; then
    segs+=("$GREEN|$label")
  else
    segs+=("$YELLOW|$label ±")
  fi
fi
segs+=("$(model_color "$model")|$I_MODEL $model")
printf '%s%s' "$(fg "$CYAN")" "$CAP_L"   # outward arrow opening row 1
powerline "${segs[@]}"

# ---------- Rows 2-4: pill progress bars ----------
until_reset() {
  local t=$1 now d
  [[ -z $t || $t == null ]] && return
  [[ $t =~ ^[0-9]+$ ]] || t=$(date -d "$t" +%s 2>/dev/null) || return
  now=$(date +%s); d=$(( t - now )); (( d < 0 )) && d=0
  if (( d >= 86400 )); then printf '↻ %dd%dh' $((d/86400)) $((d%86400/3600))
  elif (( d >= 3600 )); then printf '↻ %dh%dm' $((d/3600)) $((d%3600/60))
  else printf '↻ %dm' $((d/60)); fi
}

# pill LABEL PERCENT RIGHT_TEXT WIDTH  →  ( 󰍛 context ▰▰▰▰▱▱▱▱▱▱▱▱   23% )
# Whole pill takes the usage color. A full row is terminal − STATUSLINE_MARGIN (default 4) wide,
# since Claude Code pads the status line area and a full-width row wraps.
LABEL_W=11; RIGHT_W=15
MARGIN=${STATUSLINE_MARGIN:-4}
ROW_W=$(( W - MARGIN ))
# pad by character count (bash printf %-Ns pads by bytes, which breaks on glyphs)
pad_r() { local s=" $1 "; printf '%s%*s' "$s" $(( $2 - ${#s} > 0 ? $2 - ${#s} : 0 )) ''; }
pad_l() { local s=" $1 "; printf '%*s%s' $(( $2 - ${#s} > 0 ? $2 - ${#s} : 0 )) '' "$s"; }
pill() {
  local label=$1 pct=$2 right=$3 width=$4 color n i bar=""
  color=$(usage_color "$pct")
  local track=$(( width - 2 - LABEL_W - RIGHT_W ))   # 2 = arrow caps
  (( track < 3 )) && track=3
  n=$(awk -v p="$pct" -v w="$track" 'BEGIN{ if (p<0) p=0; if (p>100) p=100; printf "%d", p*w/100 + 0.5 }')
  (( n == 0 )) && awk -v p="$pct" 'BEGIN{exit !(p>0)}' && n=1    # any usage shows at least one cell
  for (( i = 0; i < track; i++ )); do (( i < n )) && bar+=$CELL_ON || bar+=$CELL_OFF; done

  printf '%s%s%s%s%s%s%s' \
    "$(fg "$color")" "$CAP_L" \
    "$(fg "$TEXT")$(bg "$color")" "$(pad_r "$label" "$LABEL_W")" "$bar" "$(pad_l "$right" "$RIGHT_W")" \
    "$R$(fg "$color")$CAP_R$R"
}

pct_txt() { printf '%3.0f%%' "$1"; }

# ---------- Which Claude account is this? ----------
# `claude-personal` runs with CLAUDE_CONFIG_DIR=~/.claude-personal → profile "personal"; plain `claude` → "work"
PROFILE=work
if [[ -n $CLAUDE_CONFIG_DIR && $(readlink -f "$CLAUDE_CONFIG_DIR") != $(readlink -f "$HOME/.claude") ]]; then
  PROFILE=${CLAUDE_CONFIG_DIR%/}; PROFILE=${PROFILE##*/}; PROFILE=${PROFILE#.}; PROFILE=${PROFILE#claude-}
fi
# Extra usage rows per account: work uses Cursor, personal uses VS Code Copilot. Override with STATUSLINE_EXTRAS.
case $PROFILE in
  work) EXTRAS=${STATUSLINE_EXTRAS-cursor} ;;
  *)    EXTRAS=${STATUSLINE_EXTRAS-copilot} ;;
esac

# Rows are "label<US>pct<US>right"; each LINE holds one row (full width) or two (50/50)
US=$'\x1f'
lines=()
add_line() { local IFS=$'\x1e'; [[ $# -gt 0 ]] && lines+=("$*"); }   # \x1e between the pills of one line
row() { printf '%s' "$1$US$2$US$3"; }

[[ -n $ctx ]] && add_line "$(row "$I_CTX context" "$ctx" "$(pct_txt "$ctx")")"
pair=()
[[ -n $sess ]] && pair+=("$(row "$I_SESS session" "$sess" "$(pct_txt "$sess") $(until_reset "$sess_reset")")")
[[ -n $week ]] && pair+=("$(row "$I_WEEK weekly" "$week" "$(pct_txt "$week") $(until_reset "$week_reset")")")
add_line "${pair[@]}"

# ---------- Share Claude usage with other tools (usage-alerts.sh, usage-menu.sh) ----------
HERE=$(dirname "$(readlink -f "$0")")
USAGE_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
usage_file=$USAGE_CACHE_DIR/claude-usage.json
[[ $PROFILE != work ]] && usage_file=$USAGE_CACHE_DIR/claude-usage-$PROFILE.json
if [[ -n $sess || -n $week ]]; then
  mkdir -p "$USAGE_CACHE_DIR"
  jq -n --arg s "$sess" --arg sr "$sess_reset" --arg w "$week" --arg wr "$week_reset" --arg prof "$PROFILE" '{
      updated: now | floor, profile: $prof,
      session: { used_percentage: ($s | tonumber? // null), resets_at: ($sr | tonumber? // null) },
      weekly:  { used_percentage: ($w | tonumber? // null), resets_at: ($wr | tonumber? // null) }
    }' >| "$usage_file.tmp" 2>/dev/null && mv -f "$usage_file.tmp" "$usage_file"
fi
# Threshold notifications run detached so they never slow the status line down
[[ -z $USAGE_ALERTS_OFF && -x $HERE/usage-alerts.sh ]] && ( "$HERE/usage-alerts.sh" >/dev/null 2>&1 & )

# ---------- Cursor monthly plan usage (cursor-usage.sh caches it; never blocks on the network) ----------
if [[ $EXTRAS == *cursor* && -z $CURSOR_USAGE_OFF ]]; then
  IFS=$US read -r c_auto c_api c_end < <(
    "$HERE/cursor-usage.sh" 2>/dev/null |
      jq -r '[(.individualUsage.plan.autoPercentUsed // ""), (.individualUsage.plan.apiPercentUsed // ""),
              (.billingCycleEnd // "")] | map(tostring) | join("\u001f")' 2>/dev/null
  )
  pair=()
  [[ -n $c_auto ]] && pair+=("$(row "$I_CURSOR cursor" "$c_auto" "$(pct_txt "$c_auto") $(until_reset "$c_end")")")
  [[ -n $c_api  ]] && pair+=("$(row "$I_CURSOR other" "$c_api" "$(pct_txt "$c_api") $(until_reset "$c_end")")")
  add_line "${pair[@]}"
fi

# ---------- GitHub Copilot premium requests (copilot-usage.sh caches it) ----------
if [[ $EXTRAS == *copilot* ]]; then
  IFS=$US read -r cp_used cp_end < <(
    "$HERE/copilot-usage.sh" 2>/dev/null |
      jq -r '.quota_snapshots.premium_interactions as $q
             | [(if $q and ($q.unlimited | not) then 100 - $q.percent_remaining else "" end),
                (.quota_reset_date // "")] | map(tostring) | join("\u001f")' 2>/dev/null
  )
  [[ -n $cp_used ]] && add_line "$(row "$I_COPILOT copilot" "$cp_used" "$(pct_txt "$cp_used") $(until_reset "$cp_end")")"
fi

# Label column grows to fit the longest label so bars stay aligned
for ln in "${lines[@]}"; do
  IFS=$'\x1e' read -ra cells <<<"$ln"
  for r in "${cells[@]}"; do l=${r%%"$US"*}; (( ${#l} + 2 > LABEL_W )) && LABEL_W=$(( ${#l} + 2 )); done
done
for ln in "${lines[@]}"; do
  IFS=$'\x1e' read -ra cells <<<"$ln"
  printf '\n'
  if (( ${#cells[@]} == 1 )); then
    IFS=$US read -r l pc rt <<<"${cells[0]}"; pill "$l" "$pc" "$rt" "$ROW_W"
  else
    left=$(( (ROW_W - 1) / 2 ))                       # 1-space gap; right pill takes the remainder
    IFS=$US read -r l pc rt <<<"${cells[0]}"; pill "$l" "$pc" "$rt" "$left"
    printf ' '
    IFS=$US read -r l pc rt <<<"${cells[1]}"; pill "$l" "$pc" "$rt" "$(( ROW_W - 1 - left ))"
  fi
done
exit 0
