#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Weather script directory fast path: FAIL: %s\n' "$1" >&2; exit 1; }

for file in "$ROOT/scripts/weather" "$ROOT/scripts/weather.d/common.sh"; do
    if grep -Eq 'dirname[[:space:]]+.*(BASH_SOURCE|\$0)' "$file"; then
        fail "external dirname remains in $file"
    fi
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
project="$tmp/Weather Project With Spaces"
mkdir -p "$project/scripts/weather.d" "$tmp/bin" "$tmp/config" "$tmp/data" "$tmp/state" "$tmp/cache"
cp "$ROOT/scripts/weather" "$project/scripts/weather"
cp "$ROOT/scripts/weather.d/common.sh" "$ROOT/scripts/weather.d/gismeteo.sh" "$project/scripts/weather.d/"
# A minimal env stub keeps the test focused on path resolution rather than
# the main environment's own initialization and migration helpers.
cat > "$project/scripts/env" <<'ENV'
#!/usr/bin/env bash
QS_PROJECT_DIR="${QS_PROJECT_DIR:-/test/project}"
QS_CONFIG_DIR="${QS_CONFIG_DIR:-/tmp/weather-test-config}"
QS_DATA_DIR="${QS_DATA_DIR:-/tmp/weather-test-data}"
QS_STATE_DIR="${QS_STATE_DIR:-/tmp/weather-test-state}"
QS_CACHE_DIR="${QS_CACHE_DIR:-/tmp/weather-test-cache}"
export QS_PROJECT_DIR QS_CONFIG_DIR QS_DATA_DIR QS_STATE_DIR QS_CACHE_DIR
ENV
real_dirname="$(command -v dirname)"
cat > "$tmp/bin/dirname" <<'SPY'
#!/usr/bin/env bash
printf 'dirname\n' >> "$WEATHER_DIRNAME_LOG"
exec "$WEATHER_REAL_DIRNAME" "$@"
SPY
chmod +x "$tmp/bin/dirname"
export PATH="$tmp/bin:$PATH" WEATHER_REAL_DIRNAME="$real_dirname" WEATHER_DIRNAME_LOG="$tmp/dirname.log"
export QS_PROJECT_DIR="$project" QS_CONFIG_DIR="$tmp/config" QS_DATA_DIR="$tmp/data" QS_STATE_DIR="$tmp/state" QS_CACHE_DIR="$tmp/cache"

# The invalid command exits 1 only after all entry point and sibling sources
# succeeded. Test both absolute invocation and a relative path with spaces.
set +e
absolute_output="$(bash "$project/scripts/weather" invalid 2>&1)"
absolute_status=$?
relative_output="$(cd "$project" && bash 'scripts/weather' invalid 2>&1)"
relative_status=$?
set -e
[[ $absolute_status -eq 1 && "$absolute_output" == *"Usage:"* ]] || fail "absolute path invocation failed to source siblings: $absolute_output"
[[ $relative_status -eq 1 && "$relative_output" == *"Usage:"* ]] || fail "relative path invocation failed to source siblings: $relative_output"
[[ ! -s "$WEATHER_DIRNAME_LOG" ]] || fail "weather startup launched dirname: $(<"$WEATHER_DIRNAME_LOG")"

echo 'Weather entry/common built-in path resolution, absolute/relative paths with spaces: OK'
