#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/secrets.json"

export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export WEATHER_CACHE_TTL=600
export WEATHER_CURL_OUTPUT=''
export WEATHER_CURL_FAIL=0
export WEATHER_CURL_LOG="$TMP/curl.log"
: > "$WEATHER_CURL_LOG"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
IFS= read -r request_header || exit 90
[[ "$request_header" == 'X-Gismeteo-Token: '* ]] || exit 91
printf '%s\n' "$*" >> "$WEATHER_CURL_LOG"
if [[ "$WEATHER_CURL_FAIL" == 1 ]]; then
    exit 7
fi
printf '%s\n' "$WEATHER_CURL_OUTPUT"
CURL
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

reset_cache() {
    rm -rf "$QS_CACHE_DIR"
    mkdir -p "$QS_CACHE_DIR/weather"
    : > "$WEATHER_CURL_LOG"
    WEATHER_CURL_FAIL=0
}

expect_failure_without_cache() {
    local endpoint="$1" payload="$2" cache_name="$3"
    reset_cache
    WEATHER_CURL_OUTPUT="$payload"
    if "$ROOT/scripts/weather" "$endpoint" > "$TMP/out.json" 2> "$TMP/err.log"; then
        echo "$endpoint accepted a response with the wrong JSON shape" >&2
        exit 1
    fi
    [[ ! -s "$TMP/out.json" ]] || {
        echo "$endpoint emitted data from a wrong-shaped API response" >&2
        exit 1
    }
    [[ ! -e "$QS_CACHE_DIR/weather/$cache_name" ]] || {
        echo "$endpoint cached a wrong-shaped API response" >&2
        exit 1
    }
}

# Current weather must be an object; both forecast feeds must be arrays.
expect_failure_without_cache now '{"response":[{"temperature":20}]}' 'now_.json'
expect_failure_without_cache day '{"response":{"date":{"unix":1785000000}}}' 'day__days_2.json'
expect_failure_without_cache week '{"response":{"date":{"unix":1785000000}}}' 'week__days_5.json'

# Correct endpoint shapes are returned and cached unchanged.
reset_cache
WEATHER_CURL_OUTPUT='{"response":{"temperature":22,"description":{"full":"Clear"}}}'
"$ROOT/scripts/weather" now > "$TMP/now.json"
jq -e '.temperature == 22 and .description.full == "Clear"' "$TMP/now.json" >/dev/null
jq -e 'type == "object" and .temperature == 22' "$QS_CACHE_DIR/weather/now_.json" >/dev/null

reset_cache
WEATHER_CURL_OUTPUT='{"response":[{"date":{"unix":1785000000},"temperature":{"air":{"C":21}}}]}'
"$ROOT/scripts/weather" day > "$TMP/day.json"
jq -e 'type == "array" and length == 1 and .[0].temperature.air.C == 21' "$TMP/day.json" >/dev/null
jq -e 'type == "array" and length == 1' "$QS_CACHE_DIR/weather/day__days_2.json" >/dev/null

# A fresh cache with the wrong endpoint shape is ignored and refreshed.
reset_cache
printf '%s\n' '[{"temperature":19}]' > "$QS_CACHE_DIR/weather/now_.json"
touch "$QS_CACHE_DIR/weather/now_.json"
WEATHER_CURL_OUTPUT='{"response":{"temperature":23}}'
"$ROOT/scripts/weather" now > "$TMP/refreshed-now.json"
jq -e 'type == "object" and .temperature == 23' "$TMP/refreshed-now.json" >/dev/null
[[ "$(wc -l < "$WEATHER_CURL_LOG")" -eq 1 ]] || {
    echo 'wrong-shaped fresh now cache was not refreshed exactly once' >&2
    exit 1
}

reset_cache
printf '%s\n' '{"temperature":19}' > "$QS_CACHE_DIR/weather/day__days_2.json"
touch "$QS_CACHE_DIR/weather/day__days_2.json"
WEATHER_CURL_OUTPUT='{"response":[{"temperature":{"air":{"C":24}}}]}'
"$ROOT/scripts/weather" day > "$TMP/refreshed-day.json"
jq -e 'type == "array" and .[0].temperature.air.C == 24' "$TMP/refreshed-day.json" >/dev/null
[[ "$(wc -l < "$WEATHER_CURL_LOG")" -eq 1 ]] || {
    echo 'wrong-shaped fresh forecast cache was not refreshed exactly once' >&2
    exit 1
}

# A stale cache of the wrong type is not served when the API is unavailable.
reset_cache
printf '%s\n' '[{"temperature":19}]' > "$QS_CACHE_DIR/weather/now_.json"
touch -d '2 minutes ago' "$QS_CACHE_DIR/weather/now_.json"
WEATHER_CURL_FAIL=1
if WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale-wrong-type.json" 2> "$TMP/stale-wrong-type.err"; then
    echo 'wrong-shaped stale cache was served after API failure' >&2
    exit 1
fi
[[ ! -s "$TMP/stale-wrong-type.json" ]] || {
    echo 'wrong-shaped stale cache emitted content' >&2
    exit 1
}

echo 'Weather endpoint response and cache shape validation: object current feed, array forecasts, wrong-shape cache refresh/rejection: OK'
