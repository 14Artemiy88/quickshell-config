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
printf '%s\n' called >> "$WEATHER_CURL_LOG"
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

expect_api_rejected() {
    local endpoint="$1" payload="$2"
    reset_cache
    WEATHER_CURL_OUTPUT="$payload"
    if "$ROOT/scripts/weather" "$endpoint" > "$TMP/out.json" 2> "$TMP/err.log"; then
        echo "$endpoint accepted multiple top-level JSON documents" >&2
        exit 1
    fi
    [[ ! -s "$TMP/out.json" ]] || {
        echo "$endpoint emitted concatenated API documents" >&2
        exit 1
    }
    [[ -z "$(find "$QS_CACHE_DIR/weather" -maxdepth 1 -type f -name '*.json' -print -quit)" ]] || {
        echo "$endpoint cached concatenated API documents" >&2
        exit 1
    }
}

# Even when each document is individually valid and has the expected shape,
# an HTTP body containing more than one JSON value is not a single API response.
expect_api_rejected now $'{"response":{"temperature":20}}\n{"response":{"temperature":21}}'
expect_api_rejected day $'{"response":[{"temperature":20}]}\n{"response":[{"temperature":21}]}'

# A valid single document remains accepted and compactly cached.
reset_cache
WEATHER_CURL_OUTPUT='{"response":{"temperature":22}}'
"$ROOT/scripts/weather" now > "$TMP/valid.json"
jq -e 'type == "object" and .temperature == 22' "$TMP/valid.json" >/dev/null
[[ "$(wc -l < "$WEATHER_CURL_LOG")" -eq 1 ]]

# A fresh cache with multiple documents is rejected and refreshed exactly once.
reset_cache
printf '%s\n%s\n' '{"temperature":19}' '{"temperature":20}' > "$QS_CACHE_DIR/weather/now_.json"
touch "$QS_CACHE_DIR/weather/now_.json"
WEATHER_CURL_OUTPUT='{"response":{"temperature":23}}'
"$ROOT/scripts/weather" now > "$TMP/refreshed.json"
jq -e '.temperature == 23' "$TMP/refreshed.json" >/dev/null
[[ "$(wc -l < "$WEATHER_CURL_LOG")" -eq 1 ]] || {
    echo 'multi-document fresh cache was not refreshed exactly once' >&2
    exit 1
}

# A stale multi-document cache must not be returned when the API is unavailable.
reset_cache
printf '%s\n%s\n' '{"temperature":19}' '{"temperature":20}' > "$QS_CACHE_DIR/weather/now_.json"
touch -d '2 minutes ago' "$QS_CACHE_DIR/weather/now_.json"
WEATHER_CURL_FAIL=1
if WEATHER_CACHE_TTL=1 "$ROOT/scripts/weather" now > "$TMP/stale.json" 2> "$TMP/stale.err"; then
    echo 'multi-document stale cache was served after API failure' >&2
    exit 1
fi
[[ ! -s "$TMP/stale.json" ]]

# The generic cache validator has the same single-document contract.
source "$ROOT/scripts/weather.d/common.sh"
weather_payload_usable '{"ok":true}' any
if weather_payload_usable $'{"ok":true}\n{"ok":false}' any; then
    echo 'generic weather payload validator accepted multiple JSON documents' >&2
    exit 1
fi

printf 'Weather single-document API/cache validation: OK\n'
