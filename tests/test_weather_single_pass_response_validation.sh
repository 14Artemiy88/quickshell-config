#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REAL_JQ="$(command -v jq)"
REAL_CAT="$(command -v cat)"
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/cache-invalid" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"

export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export WEATHER_TEST_RESPONSE='{"response":{"temperature":21,"summary":"fresh"}}'
export WEATHER_JQ_LOG="$TMP/jq.log"
export WEATHER_CAT_LOG="$TMP/cat.log"
export REAL_JQ REAL_CAT
: > "$WEATHER_JQ_LOG"
: > "$WEATHER_CAT_LOG"

cat > "$TMP/bin/jq" <<'STUB'
#!/usr/bin/env bash
printf 'jq\n' >> "$WEATHER_JQ_LOG"
exec "$REAL_JQ" "$@"
STUB
cat > "$TMP/bin/cat" <<'STUB'
#!/usr/bin/env bash
printf 'cat\n' >> "$WEATHER_CAT_LOG"
exec "$REAL_CAT" "$@"
STUB
cat > "$TMP/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "${WEATHER_TEST_RESPONSE:-}" 
STUB
chmod +x "$TMP/bin/jq" "$TMP/bin/cat" "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

"$ROOT/scripts/weather" now > "$TMP/valid.json"
"$REAL_JQ" -e '.temperature == 21 and .summary == "fresh"' "$TMP/valid.json" >/dev/null
[[ -s "$TMP/cache/weather/now_.json" ]] || {
    echo 'valid response was not cached' >&2
    exit 1
}
# Cold-cache success should need one jq for the token and one jq that both
# extracts and validates the API payload. Cache publishing must not spawn cat
# or another jq to re-parse the bytes just written.
jq_count="$(wc -l < "$WEATHER_JQ_LOG")"
[[ "$jq_count" -eq 2 ]] || {
    echo "expected two jq processes on successful refresh, observed: $(<"$WEATHER_JQ_LOG")" >&2
    exit 1
}
[[ ! -s "$WEATHER_CAT_LOG" ]] || {
    echo "unexpected cat process during cache publish: $(<"$WEATHER_CAT_LOG")" >&2
    exit 1
}

# A response that is valid JSON but has the wrong payload shape must be rejected
# by the same API parser, not written into the cache or returned to the widget.
export QS_CACHE_DIR="$TMP/cache-invalid"
export WEATHER_TEST_RESPONSE='{"response":"not-weather-data"}'
set +e
"$ROOT/scripts/weather" now > "$TMP/invalid.json" 2> "$TMP/invalid.err"
status=$?
set -e
[[ $status -ne 0 ]] || {
    echo 'invalid response shape unexpectedly succeeded' >&2
    exit 1
}
[[ ! -s "$TMP/invalid.json" ]] || {
    echo 'invalid response shape emitted payload data' >&2
    exit 1
}
[[ ! -e "$TMP/cache-invalid/weather/now_.json" ]] || {
    echo 'invalid response shape was cached' >&2
    exit 1
}

echo 'Weather single-pass API response validation and cache publish: OK'
