#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export CURL_CALL_LOG="$TMP/curl-calls.log"
export PATH="$TMP/bin:$PATH"

cat > "$TMP/bin/curl" <<'MOCK_CURL'
#!/bin/bash
printf 'call\n' >> "$CURL_CALL_LOG"
sleep 0.4
if [[ "${CURL_MODE:-fail}" == "ok" ]]; then
    printf '%s\n' '{"response":{"temperature":21,"summary":"fresh forecast"}}'
    exit 0
fi
exit 7
MOCK_CURL
chmod +x "$TMP/bin/curl"

# Two concurrent cold-cache requests should share a single successful fetch.
export CURL_MODE=ok
WEATHER_CACHE_TTL=600 "$ROOT/scripts/weather" now > "$TMP/success-a.json" 2>"$TMP/success-a.err" & p1=$!
WEATHER_CACHE_TTL=600 "$ROOT/scripts/weather" now > "$TMP/success-b.json" 2>"$TMP/success-b.err" & p2=$!
wait "$p1"
wait "$p2"
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]]
jq -e '.temperature == 21 and .summary == "fresh forecast"' "$TMP/success-a.json" >/dev/null
jq -e '.temperature == 21 and .summary == "fresh forecast"' "$TMP/success-b.json" >/dev/null

# Expired cache + failing API: parallel polls should make one attempt, then
# both receive stale data. Repeated polls stay in retry cooldown, while --force
# explicitly bypasses that cooldown.
CACHE="$TMP/cache/weather/now_.json"
printf '%s\n' '{"temperature":17,"summary":"stale forecast"}' > "$CACHE"
touch -d '2 minutes ago' "$CACHE"
: > "$CURL_CALL_LOG"
export CURL_MODE=fail
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale-a.json" 2>"$TMP/stale-a.err" & p1=$!
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale-b.json" 2>"$TMP/stale-b.err" & p2=$!
wait "$p1"
wait "$p2"
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]]
jq -e '.temperature == 17 and .summary == "stale forecast"' "$TMP/stale-a.json" >/dev/null
jq -e '.temperature == 17 and .summary == "stale forecast"' "$TMP/stale-b.json" >/dev/null
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/cooldown.json" 2>"$TMP/cooldown.err"
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]]
jq -e '.temperature == 17' "$TMP/cooldown.json" >/dev/null
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now --force > "$TMP/forced.json" 2>"$TMP/forced.err"
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 2 ]]
jq -e '.temperature == 17' "$TMP/forced.json" >/dev/null

# The per-key lock remains private and no partial temporary files are left.
[[ "$(stat -c %a "$CACHE.lock")" == "600" ]]
if find "$TMP/cache/weather" -maxdepth 1 -type f -name 'now_*.json.*' \
        ! -name '*.lock' ! -name '*.attempt' | grep -q .; then
    echo 'weather cache left temporary files behind' >&2
    exit 1
fi

echo 'Weather request concurrency test: OK'
