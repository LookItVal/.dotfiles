#!/usr/bin/env bash
# Fetch Claude plan usage (5h session + weekly) straight from Anthropic for every Claude Code login,
# so the rofi popup / alerts don't depend on the status line having run recently.
# Uses the OAuth login Claude Code already stored (<config dir>/.credentials.json). The token is only
# held in a variable and sent to api.anthropic.com — never printed. Note: this is the same (undocumented)
# endpoint Claude Code's /usage uses, so it could change without notice; the status line still feeds
# the same cache files as a fallback.
#
#   claude-usage.sh          → refresh caches older than CLAUDE_USAGE_TTL seconds (default 120), in parallel
#   claude-usage.sh --force  → refresh regardless of age
# Writes ~/.cache/claude-statusline/claude-usage.json (work) and claude-usage-<profile>.json (others).
export LC_ALL=C.UTF-8
DIR=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
TTL=${CLAUDE_USAGE_TTL:-120}
[[ $1 == --force ]] && TTL=0
URL=https://api.anthropic.com/api/oauth/usage
mkdir -p "$DIR"

# "profile config-dir" — work is the default ~/.claude, personal is the claude-personal alias's dir
PROFILES=("work $HOME/.claude" "personal $HOME/.claude-personal")

epoch() { [[ -n $1 && $1 != null ]] && date -d "$1" +%s 2>/dev/null; }

fetch_one() {
  local profile=$1 cfg=$2 out tok exp resp s sr w wr
  out=$DIR/claude-usage.json; [[ $profile != work ]] && out=$DIR/claude-usage-$profile.json
  [[ -f $out ]] && (( $(date +%s) - $(stat -c %Y "$out") < TTL )) && return 0
  [[ -f $cfg/.credentials.json ]] || return 1

  IFS=$'\t' read -r tok exp < <(jq -r '.claudeAiOauth | [.accessToken, .expiresAt] | map(tostring) | @tsv' \
                                    "$cfg/.credentials.json" 2>/dev/null)
  [[ -n $tok && $tok != null ]] || return 1
  # Expired tokens get refreshed by Claude Code itself next time that account is used; just skip until then
  [[ $exp =~ ^[0-9]+$ ]] && (( exp / 1000 < $(date +%s) )) && return 1

  resp=$(curl -sf -m 5 "$URL" -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" \
              -H "Accept: application/json") || return 1
  unset tok
  IFS=$'\t' read -r s sr w wr < <(jq -r '[.five_hour.utilization, .five_hour.resets_at,
      .seven_day.utilization, .seven_day.resets_at] | map(tostring) | @tsv' <<<"$resp" 2>/dev/null)
  [[ $s == null && $w == null ]] && return 1

  jq -n --arg s "$s" --arg sr "$(epoch "$sr")" --arg w "$w" --arg wr "$(epoch "$wr")" --arg prof "$profile" '{
      updated: now | floor, profile: $prof, source: "api",
      session: { used_percentage: ($s | tonumber? // null), resets_at: ($sr | tonumber? // null) },
      weekly:  { used_percentage: ($w | tonumber? // null), resets_at: ($wr | tonumber? // null) }
    }' >| "$out.api.tmp" && mv -f "$out.api.tmp" "$out"
}

for p in "${PROFILES[@]}"; do fetch_one $p & done
wait
exit 0
