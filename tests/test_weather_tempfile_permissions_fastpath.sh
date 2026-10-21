#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache/weather" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
: > "$TMP/config/.migration-settings-v1"
: > "$TMP/data/.migration-calendar-notes-v1"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config" QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"

# Source before installing spies so any environment initialization is outside
# the measured function calls. mktemp outputs must be private by default.
source "$ROOT/scripts/weather.d/common.sh"
REAL_CHMOD="$(command -v chmod)"
export WEATHER_CHMOD_LOG="$TMP/chmod.log" WEATHER_REAL_CHMOD="$REAL_CHMOD"
cat > "$TMP/bin/chmod" <<'MOCK_CHMOD'
#!/usr/bin/env bash
printf 'chmod %s\n' "$*" >> "$WEATHER_CHMOD_LOG"
exec "$WEATHER_REAL_CHMOD" "$@"
MOCK_CHMOD
chmod +x "$TMP/bin/chmod"
export PATH="$TMP/bin:$PATH"

CACHE="$TMP/cache/weather/forecast.json"
ATTEMPT="$TMP/cache/weather/forecast.attempt"
weather_cache_write "$CACHE" '{"temperature":17,"summary":"ok"}' || { echo 'cache write failed' >&2; exit 1; }
weather_mark_attempt "$ATTEMPT" 1234567890 || { echo 'attempt write failed' >&2; exit 1; }
[[ "$(cat "$CACHE")" == '{"temperature":17,"summary":"ok"}' ]] || { echo 'cache payload changed' >&2; exit 1; }
[[ "$(cat "$ATTEMPT")" == '1234567890' ]] || { echo 'attempt timestamp changed' >&2; exit 1; }
[[ "$(stat -c %a "$CACHE")" == 600 ]] || { echo "cache mode is not 0600: $(stat -c %a "$CACHE")" >&2; exit 1; }
[[ "$(stat -c %a "$ATTEMPT")" == 600 ]] || { echo "attempt marker mode is not 0600: $(stat -c %a "$ATTEMPT")" >&2; exit 1; }
[[ ! -s "$WEATHER_CHMOD_LOG" ]] || { echo "weather temp writer still invokes chmod: $(<"$WEATHER_CHMOD_LOG")" >&2; exit 1; }
grep -Fq 'mktemp "${cache_file}.XXXXXX"' "$ROOT/scripts/weather.d/common.sh" || { echo 'cache writer stopped using mktemp' >&2; exit 1; }
grep -Fq 'mktemp "${attempt_file}.XXXXXX"' "$ROOT/scripts/weather.d/common.sh" || { echo 'attempt writer stopped using mktemp' >&2; exit 1; }
grep -Fq 'test_weather_tempfile_permissions_fastpath.sh' "$ROOT/CHECK.sh" || { echo 'weather tempfile permissions test is not registered in CHECK.sh' >&2; exit 1; }
echo 'Weather temp-file permissions fast path: mktemp outputs remain 0600 without per-write chmod'
