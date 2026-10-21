#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/mopidy/mixer.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
fail() { printf 'Mopidy mixer batched get: FAIL: %s\n' "$*" >&2; exit 1; }
REAL_JQ="$(command -v jq)"
export REAL_JQ
mkdir -p "$TMP/bin"
cat > "$TMP/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
set -euo pipefail
printf 'call\n' >> "$CURL_COUNT"
body=''
while (($#)); do
    case "$1" in
        -d) body="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
printf '%s\n' "$body" > "$REQUEST_BODY"
if [[ "${MOCK_CURL_FAIL:-0}" == 1 ]]; then exit 7; fi
while IFS= read -r line || [[ -n "$line" ]]; do printf '%s\n' "$line"; done < "$MOCK_RESPONSE_FILE"
MOCK_CURL
cat > "$TMP/bin/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
printf 'call\n' >> "$JQ_COUNT"
exec "$REAL_JQ" "$@"
MOCK_JQ
chmod +x "$TMP/bin/curl" "$TMP/bin/jq"
export PATH="$TMP/bin:$PATH"
export CURL_COUNT="$TMP/curl-count" JQ_COUNT="$TMP/jq-count"
export REQUEST_BODY="$TMP/request.json" MOCK_RESPONSE_FILE="$TMP/response.json"

cat > "$MOCK_RESPONSE_FILE" <<'RESP'
[
  {"jsonrpc":"2.0","id":2,"result":false},
  {"jsonrpc":"2.0","id":1,"result":73}
]
RESP
: > "$CURL_COUNT"; : > "$JQ_COUNT"
actual="$(MOPIDY_RPC_URL='http://mock.invalid/rpc' bash "$SCRIPT" get)"
curl_calls="$(wc -l < "$CURL_COUNT")"
jq_calls="$(wc -l < "$JQ_COUNT")"
[[ "$actual" == '{"ok":true,"volume":73,"mute":false}' ]] || fail "bad batched volume/mute result: $actual"
[[ "$curl_calls" == 1 ]] || fail "get should make one curl call, got $curl_calls"
[[ "$jq_calls" == 1 ]] || fail "get should make one jq call after the response, got $jq_calls"
"$REAL_JQ" -e 'type == "array" and length == 2 and .[0].id == 1 and .[0].method == "core.mixer.get_volume" and .[1].id == 2 and .[1].method == "core.mixer.get_mute"' "$REQUEST_BODY" >/dev/null || fail "request is not a two-method JSON-RPC batch"

# A successful partial batch should preserve the valid side and mark the
# failed side null, matching the previous two-request behavior.
cat > "$MOCK_RESPONSE_FILE" <<'RESP'
[
  {"jsonrpc":"2.0","id":1,"error":{"message":"volume unavailable"}},
  {"jsonrpc":"2.0","id":2,"result":true}
]
RESP
: > "$CURL_COUNT"; : > "$JQ_COUNT"
actual="$(MOPIDY_RPC_URL='http://mock.invalid/rpc' bash "$SCRIPT" get)"
[[ "$actual" == '{"ok":true,"volume":null,"mute":true}' ]] || fail "valid mute was lost when volume failed: $actual"
[[ "$(wc -l < "$CURL_COUNT")" == 1 ]] || fail "partial batch used multiple requests"

# If neither method returns a usable result, retain the structured failure.
cat > "$MOCK_RESPONSE_FILE" <<'RESP'
[
  {"jsonrpc":"2.0","id":1,"error":{"message":"unsupported"}},
  {"jsonrpc":"2.0","id":2,"error":{"message":"unsupported"}}
]
RESP
actual="$(MOPIDY_RPC_URL='http://mock.invalid/rpc' bash "$SCRIPT" get)"
[[ "$actual" == '{"ok":false,"volume":null,"mute":null}' ]] || fail "unavailable batch results did not produce failure: $actual"

# Preserve the legacy distinction between "no value" and an invalid but
# non-empty server result: the latter reports ok=true while its field is null.
cat > "$MOCK_RESPONSE_FILE" <<'RESP'
[
  {"jsonrpc":"2.0","id":1,"result":"not-a-number"},
  {"jsonrpc":"2.0","id":2,"result":"unknown"}
]
RESP
actual="$(MOPIDY_RPC_URL='http://mock.invalid/rpc' bash "$SCRIPT" get)"
[[ "$actual" == '{"ok":true,"volume":null,"mute":null}' ]] || fail "non-empty invalid results changed legacy ok semantics: $actual"

# Transport failure must not start jq and must retain the old fallback shape.
: > "$CURL_COUNT"; : > "$JQ_COUNT"
actual="$(MOCK_CURL_FAIL=1 MOPIDY_RPC_URL='http://mock.invalid/rpc' bash "$SCRIPT" get)"
[[ "$actual" == '{"ok":false,"volume":null,"mute":null}' ]] || fail "transport failure output changed: $actual"
[[ "$(wc -l < "$CURL_COUNT")" == 1 ]] || fail "transport failure should attempt one request"
[[ ! -s "$JQ_COUNT" ]] || fail "jq should not start on transport failure"

# The write/action paths remain present and keep their prior RPC methods.
grep -q "core.mixer.set_volume" "$SCRIPT" || fail "set_volume RPC was removed"
grep -q "core.mixer.set_mute" "$SCRIPT" || fail "set_mute RPC was removed"
grep -q "core.mixer.get_mute" "$SCRIPT" || fail "mute toggle read was removed"

echo 'Mopidy mixer batch get: one request, one parse, partial/error handling OK'
