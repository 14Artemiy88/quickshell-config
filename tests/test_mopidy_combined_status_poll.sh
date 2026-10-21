#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin"
REAL_JQ="$(command -v jq)"
export REAL_JQ CURL_LOG="$TMP_DIR/curl-calls" JQ_CALL_LOG="$TMP_DIR/jq-calls"
export PATH="$TMP_DIR/bin:$PATH"
fail() { echo "Mopidy combined status polling: FAIL: $*" >&2; exit 1; }

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'curl\n' >> "$CURL_LOG"
data=''
while (($#)); do
    case "$1" in
        -d) data="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
if [[ "$data" == *'"id":5'* && "$data" == *'core.mixer.get_volume'* &&
      "$data" == *'core.mixer.get_mute'* && "$data" == *'core.tracklist.get_random'* &&
      "$data" == *'core.tracklist.get_repeat'* && "$data" == *'core.tracklist.get_single'* ]]; then
    cat <<'JSON'
[
 {"jsonrpc":"2.0","id":1,"result":63},
 {"jsonrpc":"2.0","id":2,"result":false},
 {"jsonrpc":"2.0","id":3,"result":true},
 {"jsonrpc":"2.0","id":4,"result":false},
 {"jsonrpc":"2.0","id":5,"result":true}
]
JSON
elif [[ "$data" == *'core.mixer.get_volume'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":63}\n'
elif [[ "$data" == *'core.mixer.get_mute'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":false}\n'
elif [[ "$data" == *'core.tracklist.get_random'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":true}\n'
elif [[ "$data" == *'core.tracklist.get_repeat'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":false}\n'
elif [[ "$data" == *'core.tracklist.get_single'* ]]; then
    printf '{"jsonrpc":"2.0","id":1,"result":true}\n'
else
    printf '{}\n'
fi
STUB
cat > "$TMP_DIR/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$JQ_CALL_LOG"
exec "$REAL_JQ" "$@"
STUB
chmod +x "$TMP_DIR/bin/curl" "$TMP_DIR/bin/jq"

output="$("$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '
  .mixer.ok == true and .mixer.volume == 63 and .mixer.mute == false and
  .playback.ok == true and .playback.random == true and
  .playback.repeat == false and .playback.single == true
' <<< "$output" >/dev/null || fail "batched response was not normalized correctly: $output"
[[ "$(wc -l < "$CURL_LOG")" -eq 1 ]] || fail "expected one curl call, got $(wc -l < "$CURL_LOG")"
[[ "$(wc -l < "$JQ_CALL_LOG")" -eq 1 ]] || fail "expected one jq call, got $(wc -l < "$JQ_CALL_LOG")"

# A volume of zero and false boolean values must survive JSON normalization.
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
cat <<'JSON'
[
 {"id":1,"result":0}, {"id":2,"result":false},
 {"id":3,"result":false}, {"id":4,"result":false}, {"id":5,"result":false}
]
JSON
STUB
chmod +x "$TMP_DIR/bin/curl"
output="$("$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '.mixer.ok == true and .mixer.volume == 0 and .mixer.mute == false and .playback.ok == true and .playback.random == false and .playback.repeat == false and .playback.single == false' <<< "$output" >/dev/null || fail "zero/false values were lost: $output"

# Offline RPC should produce valid JSON and mark both groups unavailable.
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
exit 7
STUB
chmod +x "$TMP_DIR/bin/curl"
output="$("$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '.mixer.ok == false and .mixer.volume == null and .playback.ok == false' <<< "$output" >/dev/null || fail "offline fallback is invalid: $output"
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf 'not-json\n'
STUB
chmod +x "$TMP_DIR/bin/curl"
output="$("$ROOT/scripts/mopidy/status.sh" state 2>/dev/null)"
"$REAL_JQ" -e '.mixer.ok == false and .playback.ok == false' <<< "$output" >/dev/null || fail "malformed RPC fallback is invalid: $output"
if "$ROOT/scripts/mopidy/status.sh" invalid >/dev/null 2>&1; then
    fail "unsupported mode was accepted"
fi

qml="$ROOT/components/mopidy/Mopidy.qml"
[[ "$(grep -c 'id: mopidyStatusProcess' "$qml")" -eq 1 ]] || fail "combined status process missing or duplicated"
if grep -qE 'id: (mixerProcess|playbackPrefsProcess)([^A-Za-z]|$)' "$qml"; then
    fail "separate mixer/playback preference poller remains"
fi
[[ "$(grep -c 'onTriggered: root.refreshMopidyStatus()' "$qml")" -eq 1 ]] || fail "expected one shared settings polling timer"
grep -Fq 'scripts/mopidy/status.sh' "$qml" || fail "QML does not invoke the combined status script"

printf 'Mopidy combined status polling: OK\n'
