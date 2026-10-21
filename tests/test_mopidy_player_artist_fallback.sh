#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
REAL_JQ="$(command -v jq)"
export REAL_JQ HOME="$TMP_DIR/home" XDG_RUNTIME_DIR="$TMP_DIR/runtime" XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/cache"
export QS_PROJECT_DIR="$ROOT" MOPIDY_RPC_URL='http://mopidy.test/mopidy/rpc' PATH="$TMP_DIR/bin:$PATH"
fail() { echo "Mopidy Player artist fallback: FAIL: $*" >&2; exit 1; }

cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
exec "$REAL_JQ" "$@"
STUB
cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/usr/bin/env bash
[[ "${1:-}" == '-x' && "${2:-}" == 'mopidy' ]]
STUB
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
body=""
while (($#)); do
  case "$1" in
    -d) body="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ "$body" == *"core.library.lookup"* ]]; then
  printf '%s' "${MOPIDY_LOOKUP_RESPONSE:-[]}"
else
  printf '%s' "${MOPIDY_RESPONSE:-}"
fi
STUB
chmod +x "$TMP_DIR/bin/jq" "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/curl"

run_backend() {
  bash -c '
    source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
    source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
    # Simulate missing artwork: Player.qml displays the JSON text/artist field.
    mopidy_cover_for_track() { printf "%s\\n" "$DEFAULT_IMG"; }
    get_mopidy_player_metadata
  '
}

# Some providers omit track.artists but do provide the artist on the album.
export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":1,"result":"playing"},
  {"jsonrpc":"2.0","id":2,"result":{"track":{"name":"Track title","artists":[],"album":{"name":"Album","artists":[{"name":"Artist from album"}]},"length":180000,"uri":"local:track:1"}}},
  {"jsonrpc":"2.0","id":3,"result":12000}
]'
output="$(run_backend)"
"$REAL_JQ" -e --arg img "$QS_PROJECT_DIR/assets/1px.png" '
  .player == "mopidy" and .image == $img and .first_line == "Track title" and .text == "Artist from album"
' <<< "$output" >/dev/null || fail "album artist was not used for the no-cover fallback: $output"

# Track-level artist metadata has priority over album artist metadata and can
# be represented either as named objects or as plain strings.
export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":2,"result":{"track":{"name":"Another track","artists":[{"name":"Track Artist A"},{"name":"Track Artist B"}],"artist":"Legacy Track Artist","album":{"artists":[{"name":"Album Artist"}]},"length":200000,"uri":"local:track:2"}}},
  {"jsonrpc":"2.0","id":1,"result":"paused"},
  {"jsonrpc":"2.0","id":3,"result":0}
]'
output="$(run_backend)"
"$REAL_JQ" -e '.text == "Track Artist A, Track Artist B"' <<< "$output" >/dev/null || fail "track artist list lost precedence: $output"

export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":1,"result":"playing"},
  {"jsonrpc":"2.0","id":2,"result":{"track":{"name":"String artists","artists":["Artist One","Artist Two"],"album":{},"length":200000,"uri":"local:track:3"}}},
  {"jsonrpc":"2.0","id":3,"result":1000}
]'
output="$(run_backend)"
"$REAL_JQ" -e '.text == "Artist One, Artist Two"' <<< "$output" >/dev/null || fail "string artist list was not handled: $output"


# Some providers omit artist data in the current playback snapshot but expose it
# through library.lookup. The lazy fallback must recover the real artist rather
# than leaving the generic Music label in Player.
export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":1,"result":"playing"},
  {"jsonrpc":"2.0","id":2,"result":{"tlid":44,"track":{"name":"Lookup metadata track","artists":[],"album":{},"length":180000,"uri":"local:track:lookup"}}},
  {"jsonrpc":"2.0","id":3,"result":1000}
]'
export MOPIDY_LOOKUP_RESPONSE='[
  {"jsonrpc":"2.0","id":10,"result":{"local:track:lookup":[{"name":"Lookup metadata track","artists":[{"name":"Recovered Library Artist"}],"album":{}}]}},
  {"jsonrpc":"2.0","id":11,"result":[]}
]'
output="$(run_backend)"
"$REAL_JQ" -e '.text == "Recovered Library Artist"' <<< "$output" >/dev/null || fail "artist was not recovered from core.library.lookup: $output"

# If library lookup lacks artists, try the exact tracklist entry for current tlid.
export MOPIDY_LOOKUP_RESPONSE='[
  {"jsonrpc":"2.0","id":10,"result":{"local:track:lookup":[]}},
  {"jsonrpc":"2.0","id":11,"result":[{"tlid":44,"track":{"name":"Lookup metadata track","artists":[{"name":"Recovered Queue Artist"}],"album":{}}}]}
]'
output="$(run_backend)"
"$REAL_JQ" -e '.text == "Recovered Queue Artist"' <<< "$output" >/dev/null || fail "artist was not recovered from current tracklist entry: $output"

echo 'Mopidy Player artist fallback: OK'
