#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache" "$TMP/home" "$TMP/cache/weather"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
# Existing paths and migration markers keep env startup out of the measured path.
: > "$TMP/config/.migration-settings-v1"
: > "$TMP/data/.migration-calendar-notes-v1"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config" QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
export WEATHER_EXTERNAL_LOG="$TMP/external.log" WEATHER_JQ_LOG="$TMP/jq.log"
REAL_MKDIR="$(command -v mkdir)"
REAL_JQ="$(command -v jq)"
cat > "$TMP/bin/mkdir" <<'MOCK_MKDIR'
#!/usr/bin/env bash
printf 'mkdir %s\n' "$*" >> "$WEATHER_EXTERNAL_LOG"
exec "$WEATHER_REAL_MKDIR" "$@"
MOCK_MKDIR
cat > "$TMP/bin/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$WEATHER_JQ_LOG"
printf 'jq\n' >> "$WEATHER_EXTERNAL_LOG"
exec "$WEATHER_REAL_JQ" "$@"
MOCK_JQ
chmod +x "$TMP/bin/mkdir" "$TMP/bin/jq"
export WEATHER_REAL_MKDIR="$REAL_MKDIR" WEATHER_REAL_JQ="$REAL_JQ"
export PATH="$TMP/bin:$PATH"

# First use still creates the cache directory, then a steady-state fresh hit
# should neither recreate it nor parse the API token from settings.json.
rm -rf "$TMP/cache/weather"
set +e
"$ROOT/scripts/weather" invalid >/dev/null 2>&1
status=$?
set -e
[[ "$status" == 1 ]] || { echo 'invalid command should still show usage and return 1' >&2; exit 1; }
[[ -d "$TMP/cache/weather" ]] || { echo 'first use did not create weather cache directory' >&2; exit 1; }
[[ "$(grep -c '^mkdir ' "$WEATHER_EXTERNAL_LOG")" == 1 ]] || { echo 'cache directory should be created only when missing' >&2; exit 1; }

CACHE="$TMP/cache/weather/now_.json"
printf '%s\n' '{"temperature":19,"summary":"cached forecast"}' > "$CACHE"
touch "$CACHE"
: > "$WEATHER_EXTERNAL_LOG"
: > "$WEATHER_JQ_LOG"
actual="$("$ROOT/scripts/weather" now)"
[[ "$actual" == '{"temperature":19,"summary":"cached forecast"}' ]] || { echo "unexpected cache payload: $actual" >&2; exit 1; }
[[ ! -s "$WEATHER_EXTERNAL_LOG" || "$(grep -c '^mkdir ' "$WEATHER_EXTERNAL_LOG" || true)" == 0 ]] || { echo 'fresh cache hit still launches mkdir' >&2; exit 1; }
[[ "$(wc -l < "$WEATHER_JQ_LOG")" == 1 ]] || { echo "fresh cache hit should run exactly one jq validation, got $(wc -l < "$WEATHER_JQ_LOG")" >&2; exit 1; }
if grep -Fq '.weatherToken' "$WEATHER_JQ_LOG"; then echo 'fresh-cache poll unnecessarily parsed the API token' >&2; exit 1; fi

# A fresh cache remains readable if the token is absent; forced refresh still
# requires a token and must fail rather than accidentally treating cache as fresh.
printf '%s\n' '{}' > "$TMP/config/settings.json"
: > "$WEATHER_EXTERNAL_LOG"
: > "$WEATHER_JQ_LOG"
actual="$("$ROOT/scripts/weather" now)"
[[ "$actual" == '{"temperature":19,"summary":"cached forecast"}' ]] || { echo 'cache hit without token did not return cached forecast' >&2; exit 1; }
[[ "$(wc -l < "$WEATHER_JQ_LOG")" == 1 ]] || { echo 'token-less cache hit should only validate the cached JSON' >&2; exit 1; }
set +e
"$ROOT/scripts/weather" now --force > "$TMP/forced.json" 2> "$TMP/forced.err"
forced_status=$?
set -e
[[ "$forced_status" != 0 ]] || { echo 'forced refresh unexpectedly succeeded without token' >&2; exit 1; }
[[ ! -s "$TMP/forced.json" ]] || { echo 'forced refresh should not return a cache hit when token is absent' >&2; exit 1; }

if ! grep -q 'test_weather_cached_poll_process_fastpath.sh' "$ROOT/CHECK.sh"; then
    echo 'Weather cached poll fast-path test is not registered in CHECK.sh' >&2
    exit 1
fi

echo 'Weather cached-poll fast path: no repeated mkdir/token jq; tokenless cache hits and forced-token checks OK'
