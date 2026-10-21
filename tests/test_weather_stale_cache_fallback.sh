#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/cache/weather" "$TMP/data" "$TMP/state" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
export CURL_CALL_LOG="$TMP/curl-calls.log"
cat > "$TMP/bin/curl" <<'MOCK_CURL'
#!/bin/bash
printf 'called\n' >> "$CURL_CALL_LOG"
exit 7
MOCK_CURL
chmod +x "$TMP/bin/curl"
export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export PATH="$TMP/bin:$PATH"

CACHE="$TMP/cache/weather/now_.json"
printf '%s\n' '{"temperature":17,"summary":"cached weather"}' > "$CACHE"
# Fresh cache should be returned without invoking curl.
WEATHER_CACHE_TTL=600 "$ROOT/scripts/weather" now > "$TMP/fresh.json"
jq -e '.temperature == 17 and .summary == "cached weather"' "$TMP/fresh.json" >/dev/null
[[ ! -s "$CURL_CALL_LOG" ]]

# Expired cache is used as stale-if-error when the API fails.
touch -d '2 minutes ago' "$CACHE"
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale.json"
jq -e '.temperature == 17 and .summary == "cached weather"' "$TMP/stale.json" >/dev/null
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]]

# Forced refresh still attempts the API, then falls back to stale data on failure.
WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now --force > "$TMP/forced-stale.json"
jq -e '.temperature == 17 and .summary == "cached weather"' "$TMP/forced-stale.json" >/dev/null
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 2 ]]

# Corrupt stale cache must not be served as weather data.
printf '%s\n' '{broken-json' > "$CACHE"
touch -d '2 minutes ago' "$CACHE"
if WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/bad-cache.json" 2>/dev/null; then
    echo 'weather request unexpectedly succeeded with failed API and corrupt cache' >&2
    exit 1
fi
[[ ! -s "$TMP/bad-cache.json" ]]
[[ "$(wc -l < "$CURL_CALL_LOG")" -eq 2 ]]
# A recent failed attempt suppresses repeated automatic requests; corrupt cache
# is not served as weather data. An explicit --force remains available to retry.

echo 'Weather stale-cache fallback test: OK'
