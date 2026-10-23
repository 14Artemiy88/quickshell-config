#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/weather"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/config" "$TMP/data" "$TMP/state" "$TMP/cache/weather" "$TMP/home"
printf '%s\n' '{"weatherToken":"test-token"}' > "$TMP/config/settings.json"
: > "$TMP/config/.migration-settings-v1"
: > "$TMP/data/.migration-calendar-notes-v1"
export HOME="$TMP/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/config"
export QS_DATA_DIR="$TMP/data" QS_STATE_DIR="$TMP/state" QS_CACHE_DIR="$TMP/cache"
export WEATHER_CACHE_TTL=600

# A warm cache for each supported endpoint proves the inline key assembly
# preserves the exact established filenames, including the empty-param key.
printf '%s\n' '{"temperature":19,"summary":"now"}' > "$TMP/cache/weather/now_.json"
printf '%s\n' '{"temperature":20,"summary":"day"}' > "$TMP/cache/weather/day__days_2.json"
printf '%s\n' '{"temperature":21,"summary":"week"}' > "$TMP/cache/weather/week__days_5.json"
for key in now day week; do touch "$TMP/cache/weather/${key}"*.json; done
[[ "$("$SCRIPT" now)" == '{"temperature":19,"summary":"now"}' ]]
[[ "$("$SCRIPT" day)" == '{"temperature":20,"summary":"day"}' ]]
[[ "$("$SCRIPT" week)" == '{"temperature":21,"summary":"week"}' ]]

python3 - "$SCRIPT" <<'PY'
from pathlib import Path
import sys
script = Path(sys.argv[1]).read_text()
assert 'cache_file=$(weather_cache_file "$cache_name" "$params")' not in script, 'cache path still uses command substitution'
assert '"$([[ "${2:-}" == "--force" ]] && echo true || echo false)"' not in script, 'force flag still forks a command-substitution subshell'
assert 'force=false\n[[ "${2:-}" == "--force" ]] && force=true' in script, 'force flag assignment is missing'
assert 'cache_file="$WEATHER_CACHE_DIR/${cache_name}_${params//[^a-zA-Z0-9]/_}.json"' in script, 'inline cache key does not preserve sanitization rules'
print('Weather entrypoint built-in assignments: key/force parsing avoid two command-substitution subshells')
PY

if ! grep -q 'test_weather_entrypoint_builtin_assignments.sh' "$ROOT/CHECK.sh"; then
    echo 'Weather entrypoint built-in assignments test is not registered in CHECK.sh' >&2
    exit 1
fi
echo 'Weather entrypoint cache-key compatibility and forced-flag regression test: OK'
