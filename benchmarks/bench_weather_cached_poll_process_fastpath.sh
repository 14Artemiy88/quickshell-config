#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
POLL_COUNT="${POLL_COUNT:-60}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/before/scripts" "$TMP/after/config" "$TMP/after/data" "$TMP/after/state" "$TMP/after/cache/weather" "$TMP/after/home"
cp -a "$ROOT/scripts/." "$TMP/before/scripts/"

# Recreate v769's old hot path from the current entrypoint: unconditional cache
# mkdir and token parsing before the fresh-cache check.
python3 - "$TMP/before/scripts/weather" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('[[ -d "$WEATHER_CACHE_DIR" ]] || mkdir -p "$WEATHER_CACHE_DIR"', 'mkdir -p "$WEATHER_CACHE_DIR"', 1)
token_line = '    token=$(weather_require_token) || return 1\n'
if s.count(token_line) != 1:
    raise SystemExit('cannot reconstruct baseline token-read location')
s = s.replace(token_line, '', 1)
needle = '    attempt_file="${cache_file}.attempt"\n'
if needle not in s:
    raise SystemExit('cannot reconstruct baseline fast-path location')
s = s.replace(needle, needle + '\n' + token_line, 1)
p.write_text(s)
PY

REAL_MKDIR="$(command -v mkdir)"
REAL_JQ="$(command -v jq)"
REAL_STAT="$(command -v stat)"
cat > "$TMP/bin/mkdir" <<'MOCK_MKDIR'
#!/usr/bin/env bash
printf 'mkdir\n' >> "$BENCH_LOG"
exec "$BENCH_REAL_MKDIR" "$@"
MOCK_MKDIR
cat > "$TMP/bin/jq" <<'MOCK_JQ'
#!/usr/bin/env bash
printf 'jq\n' >> "$BENCH_LOG"
exec "$BENCH_REAL_JQ" "$@"
MOCK_JQ
cat > "$TMP/bin/stat" <<'MOCK_STAT'
#!/usr/bin/env bash
printf 'stat\n' >> "$BENCH_LOG"
exec "$BENCH_REAL_STAT" "$@"
MOCK_STAT
chmod +x "$TMP/bin/mkdir" "$TMP/bin/jq" "$TMP/bin/stat"
export BENCH_REAL_MKDIR="$REAL_MKDIR" BENCH_REAL_JQ="$REAL_JQ" BENCH_REAL_STAT="$REAL_STAT"
export PATH="$TMP/bin:$PATH"

prepare_side() {
    local side="$1" script_root="$2"
    mkdir -p "$TMP/$side/config" "$TMP/$side/data" "$TMP/$side/state" "$TMP/$side/cache/weather" "$TMP/$side/home"
    printf '%s\n' '{"weatherToken":"bench-token"}' > "$TMP/$side/config/settings.json"
    : > "$TMP/$side/config/.migration-settings-v1"
    : > "$TMP/$side/data/.migration-calendar-notes-v1"
    printf '%s\n' '{"temperature":19,"summary":"cached forecast"}' > "$TMP/$side/cache/weather/now_.json"
    touch "$TMP/$side/cache/weather/now_.json"
}
export BENCH_LOG="$TMP/setup.log"
prepare_side before "$TMP/before"
prepare_side after "$ROOT"

run_side() {
    local side="$1" script="$2" start end i
    export HOME="$TMP/$side/home" QS_PROJECT_DIR="$ROOT" QS_CONFIG_DIR="$TMP/$side/config" QS_DATA_DIR="$TMP/$side/data" QS_STATE_DIR="$TMP/$side/state" QS_CACHE_DIR="$TMP/$side/cache" WEATHER_CACHE_TTL=600
    export BENCH_LOG="$TMP/$side.calls"
    : > "$BENCH_LOG"
    # Warm up shell startup and any one-time migration marker paths, then
    # clear counters so only steady-state fresh-cache polls are measured.
    "$script" invalid >/dev/null 2>&1 || true
    : > "$BENCH_LOG"
    start=$(/usr/bin/date +%s%N)
    for ((i=0; i<POLL_COUNT; i++)); do "$script" now >/dev/null; done
    end=$(/usr/bin/date +%s%N)
    local elapsed=$(((end-start)/1000000))
    local mkdirs jq_calls stats total
    mkdirs=$(grep -c '^mkdir$' "$BENCH_LOG" || true)
    jq_calls=$(grep -c '^jq$' "$BENCH_LOG" || true)
    stats=$(grep -c '^stat$' "$BENCH_LOG" || true)
    total=$((mkdirs+jq_calls+stats))
    printf '%s polls=%s mkdir=%s jq=%s stat=%s tracked_total=%s elapsed_ms=%s\n' "$side" "$POLL_COUNT" "$mkdirs" "$jq_calls" "$stats" "$total" "$elapsed"
}

run_side before "$TMP/before/scripts/weather"
run_side after "$ROOT/scripts/weather"
