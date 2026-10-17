#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache/weather" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
export HOME="$TMP/home"
export QS_PROJECT_DIR="$ROOT"
export QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data"
export QS_STATE_DIR="$TMP/state"
export QS_CACHE_DIR="$TMP/cache"
export EXTERNAL_CALL_LOG="$TMP/external-calls.log"
: > "$EXTERNAL_CALL_LOG"

cat > "$TMP/bin/date" <<'DATE'
#!/usr/bin/env bash
printf 'date\n' >> "$EXTERNAL_CALL_LOG"
command -p date "$@"
DATE
cat > "$TMP/bin/cat" <<'CAT'
#!/usr/bin/env bash
printf 'cat\n' >> "$EXTERNAL_CALL_LOG"
command -p cat "$@"
CAT
chmod +x "$TMP/bin/date" "$TMP/bin/cat"

# Source first, then place spies at the front of PATH. The cache test should
# need neither date nor cat in the normal Bash 5+ path.
source "$ROOT/scripts/weather.d/common.sh"
export PATH="$TMP/bin:$PATH"
CACHE="$TMP/cache/weather/fresh.json"
printf '%s\n' '{"temperature":19,"summary":"cache hit"}' > "$CACHE"
touch "$CACHE"

if [[ "${EPOCHSECONDS+x}" != x ]]; then
    echo 'EPOCHSECONDS must be available in the test Bash' >&2
    exit 1
fi
weather_cache_valid "$CACHE" || { echo 'fresh cache was incorrectly rejected' >&2; exit 1; }
payload="$(weather_cache_read_usable "$CACHE")"
[[ "$payload" == '{"temperature":19,"summary":"cache hit"}' ]] || {
    echo "cache payload changed: $payload" >&2; exit 1;
}
[[ ! -s "$EXTERNAL_CALL_LOG" ]] || {
    echo "cache hit spawned external process(es): $(<"$EXTERNAL_CALL_LOG")" >&2; exit 1;
}

# Compatibility path: simulate Bash versions/environments where EPOCHSECONDS
# is unavailable and ensure date is still used for TTL validation.
unset EPOCHSECONDS
weather_cache_valid "$CACHE" || { echo 'fallback rejected fresh cache' >&2; exit 1; }
[[ "$(<"$EXTERNAL_CALL_LOG")" == 'date' ]] || {
    echo "expected exactly one date fallback, saw: $(<"$EXTERNAL_CALL_LOG")" >&2; exit 1;
}
# The cache payload reader remains built-in even in the fallback scenario.
payload="$(weather_cache_read_usable "$CACHE")"
[[ "$payload" == '{"temperature":19,"summary":"cache hit"}' ]] || exit 1
[[ "$(<"$EXTERNAL_CALL_LOG")" == 'date' ]] || {
    echo '`cat` was unexpectedly invoked while reading cache payload' >&2; exit 1;
}

echo 'Weather cache-hit built-in fast path and date fallback: OK'
