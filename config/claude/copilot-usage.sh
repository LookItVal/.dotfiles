#!/usr/bin/env bash
# GitHub Copilot (VS Code) monthly premium-request quota, via the gh CLI's existing login.
# `gh api` handles auth itself, so the token is never read or printed by this script.
#
#   copilot-usage.sh   → cached JSON (refreshed at most every COPILOT_USAGE_TTL seconds, default 300)
#   Useful fields: .quota_snapshots.premium_interactions.percent_remaining, .quota_reset_date
set -o pipefail

CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/copilot-usage.json
TTL=${COPILOT_USAGE_TTL:-300}

# Keep only the quota bits — the full response carries account details we don't need on disk
fetch() {
  timeout 6 gh api /copilot_internal/user 2>/dev/null |
    jq '{quota_reset_date, copilot_plan, quota_snapshots}'
}

mkdir -p "${CACHE%/*}"
if [[ -f $CACHE ]] && (( $(date +%s) - $(stat -c %Y "$CACHE") < TTL )); then
  cat "$CACHE"; exit 0
fi
(
  tmp=$(mktemp "${CACHE}.XXXX") && fetch >| "$tmp" && jq -e '.quota_snapshots' "$tmp" >/dev/null && mv -f "$tmp" "$CACHE"
  rm -f "$tmp"
) >/dev/null 2>&1 &
[[ -f $CACHE ]] && cat "$CACHE"
exit 0
