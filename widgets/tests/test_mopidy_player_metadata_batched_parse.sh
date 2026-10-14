#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state" "$TMP_DIR/cache" "$TMP_DIR/home"
REAL_JQ="$(command -v jq)"
export REAL_JQ JQ_CALL_LOG="$TMP_DIR/jq-calls"
export HOME="$TMP_DIR/home" XDG_RUNTIME_DIR="$TMP_DIR/runtime" XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/cache"
export QS_PROJECT_DIR="$ROOT" MOPIDY_RPC_URL='http://mopidy.test/mopidy/rpc'
export PATH="$TMP_DIR/bin:$PATH"
fail() { echo "Mopidy player metadata batched parse: FAIL: $*" >&2; exit 1; }

cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
cat > "$TMP_DIR/bin/pgrep" <<'STUB'
#!/usr/bin/env bash
[[ "${1:-}" == '-x' && "${2:-}" == 'mopidy' ]]
STUB
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
[[ "${CURL_FAIL:-0}" == 1 ]] && exit 7
printf '%s' "${MOPIDY_RESPONSE:-}"
STUB
chmod +x "$TMP_DIR/bin/jq" "$TMP_DIR/bin/pgrep" "$TMP_DIR/bin/curl"

export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":3,"result":12345},
  {"jsonrpc":"2.0","id":2,"result":{"tlid":7,"track":{"name":"Song with \"quotes\" and\nnewline","artists":[{"name":"Artist\nA"}],"album":{"name":"Album\" title","date":"2024","uri":"local:album:1"},"length":240000,"uri":"http://music.test/track"}}},
  {"jsonrpc":"2.0","id":1,"result":"playing"}
]'

run_backend() {
  bash -c '
    source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
    source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
    mopidy_cover_for_track() { printf "%s\\n" "$DEFAULT_IMG"; }
    get_mopidy_player_metadata
  '
}

: > "$JQ_CALL_LOG"
output="$(run_backend)"
"$REAL_JQ" -e '
  .player == "mopidy" and .first_line == "Song with \"quotes\" and\nnewline" and
  .second_line == "2024 - Album\" title" and .text == "Artist\nA" and
  .position == "5" and .duration == "240000"
' <<< "$output" >/dev/null || fail "metadata changed or multiline fields were damaged: $output"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 2 ]] || fail "expected one metadata jq + one get_json jq, got $(wc -l < "$JQ_CALL_LOG")"

# A paused response with shuffled result IDs must remain valid, and optional fields
# must retain the previous safe defaults.
export MOPIDY_RESPONSE='[
  {"jsonrpc":"2.0","id":2,"result":{"tlid":8,"track":{"name":"Paused track","artists":[],"album":{},"uri":"http://music.test/paused"}}},
  {"jsonrpc":"2.0","id":1,"result":"paused"},
  {"jsonrpc":"2.0","id":3,"result":null}
]'
: > "$JQ_CALL_LOG"
output="$(run_backend)"
"$REAL_JQ" -e '.player == "mopidy" and .first_line == "Paused track" and .text == "music" and .position == "" and .duration == "0"' <<< "$output" >/dev/null || fail "paused/missing optional fields changed: $output"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 2 ]] || fail "paused track used unexpected jq count"

# Invalid/offline RPC payload must not fabricate a Mopidy player result.
export CURL_FAIL=1
: > "$JQ_CALL_LOG"
output="$(run_backend || true)"
[[ -z "$output" ]] || fail "offline Mopidy RPC unexpectedly produced metadata: $output"
# One jq parse attempt handles the empty response; no separate per-field parsing occurs.
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]] || fail "offline response ran jq more than once"

printf 'Mopidy player metadata batched parse: OK\n'
