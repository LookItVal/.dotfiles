#!/usr/bin/env bash
# Fetch Cursor's monthly plan usage using the login the Cursor app already stored locally.
# The token is read into a variable and only ever sent to cursor.com — never printed.
#
#   cursor-usage.sh           → cached JSON (refreshed at most every CURSOR_USAGE_TTL seconds, default 300)
#   cursor-usage.sh --probe   → response *shape* only: all strings redacted, numbers/bools kept
set -o pipefail

DB=${CURSOR_DB:-$HOME/.config/Cursor/User/globalStorage/state.vscdb}
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/cursor-usage.json
TTL=${CURSOR_USAGE_TTL:-300}
URL=https://cursor.com/api/usage-summary

fetch() {
  local tok sub uid
  tok=$(timeout 2 sqlite3 "file:$DB?mode=ro" "select value from ItemTable where key='cursorAuth/accessToken'" 2>/dev/null) || return 1
  [[ -n $tok ]] || return 1
  # user id lives in the JWT's "sub" claim (e.g. "auth0|user_…"); the cookie wants the part after "|"
  sub=$(cut -d. -f2 <<<"$tok" | tr '_-' '/+' | { b=$(cat); while (( ${#b} % 4 )); do b+="="; done; base64 -d <<<"$b"; } 2>/dev/null | jq -r '.sub // empty' 2>/dev/null)
  uid=${sub##*|}
  curl -sf -m 5 -H "Cookie: WorkosCursorSessionToken=${uid}%3A%3A${tok}" -H "Accept: application/json" "$URL"
}

if [[ $1 == --probe ]]; then
  fetch | jq 'walk(if type == "string" then "<str>" else . end)' || echo "request failed (exit $?)" >&2
  exit
fi

mkdir -p "${CACHE%/*}"
if [[ -f $CACHE ]] && (( $(date +%s) - $(stat -c %Y "$CACHE") < TTL )); then
  cat "$CACHE"; exit 0
fi
# Refresh in the background so the status line never waits on the network; serve the old copy meanwhile
(
  tmp=$(mktemp "${CACHE}.XXXX") && fetch >| "$tmp" && jq -e . "$tmp" >/dev/null && mv -f "$tmp" "$CACHE"
  rm -f "$tmp"
) >/dev/null 2>&1 &
[[ -f $CACHE ]] && cat "$CACHE"
exit 0
