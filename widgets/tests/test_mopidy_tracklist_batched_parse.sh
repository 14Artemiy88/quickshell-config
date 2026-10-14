#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
REAL_JQ="$(command -v jq)"
export REAL_JQ
export JQ_CALL_LOG="$TMP_DIR/jq-calls"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export HOME="$TMP_DIR/home"
export PATH="$TMP_DIR/bin:$PATH"
export MOPIDY_RPC_URL='http://mopidy.test/mopidy/rpc'
fail() { echo "Mopidy tracklist batched parse: FAIL: $*" >&2; exit 1; }

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s' "${MOPIDY_RESPONSE:-}"
STUB
cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
chmod +x "$TMP_DIR/bin/curl" "$TMP_DIR/bin/jq"

export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":3,"result":12345},
  {"jsonrpc":"2.0","id":1,"result":[
    {"tlid":7,"track":{"name":"Song with \"quotes\" and\nnewline","artists":[{"name":"Artist A"},{"name":"Artist B"}],"album":{"name":"Album","date":"2024"},"length":240000,"uri":"file:///music/song.flac"}},
    {"tlid":8,"track":{"artists":[],"album":{},"uri":"spotify:track:abc"}}
  ]},
  {"jsonrpc":"2.0","id":2,"result":{"tlid":7}}
]'
output="$("$ROOT/scripts/mopidy/tracklist.sh" get)"
"$REAL_JQ" -e '
  .ok == true and .current_tlid == 7 and .position_ms == 12345 and
  (.tracks | length) == 2 and
  .tracks[0].name == "Song with \"quotes\" and\nnewline" and
  .tracks[0].artist == "Artist A, Artist B" and .tracks[0].albumDate == "2024" and
  .tracks[0].duration == 240000 and .tracks[1].name == "Без названия" and
  .tracks[1].duration == 0
' <<< "$output" >/dev/null || fail "batch response transformed incorrectly: $output"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]] || fail "get_queue must invoke jq exactly once"

: > "$JQ_CALL_LOG"
export MOPIDY_RESPONSE='[
 {"jsonrpc":"2.0","id":1,"result":[]},
 {"jsonrpc":"2.0","id":2,"result":{}},
 {"jsonrpc":"2.0","id":3,"result":"not-a-number"}
]'
output="$("$ROOT/scripts/mopidy/tracklist.sh" get)"
"$REAL_JQ" -e '.ok == true and .current_tlid == null and .position_ms == 0 and .tracks == []' <<< "$output" >/dev/null || fail "invalid optional fields did not fall back safely: $output"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]] || fail "empty queue must still invoke jq exactly once"

# Offline handling must remain a valid single JSON response and not parse it.
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
exit 7
STUB
chmod +x "$TMP_DIR/bin/curl"
: > "$JQ_CALL_LOG"
output="$("$ROOT/scripts/mopidy/tracklist.sh" get)"
"$REAL_JQ" -e '.ok == false and .current_tlid == null and .tracks == [] and .error == "offline"' <<< "$output" >/dev/null || fail "offline fallback changed: $output"
[[ ! -s "$JQ_CALL_LOG" ]] || fail "offline fallback should not invoke jq"

printf 'Mopidy tracklist batched parse: OK\n'
