#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps system load percent: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
check() {
    local expected="$1"; shift
    local actual
    actual="$(calculate_system_load_percent "$@")"
    [[ "$actual" == "$expected" ]] || fail "expected $expected, got $actual for $*"
}
check 100.0000 100 1000 1100 2000
check 50.0000 2000 3000 2250 3500
check 33.3333 0 0 1 3
check 0.0000 100 100 99 101
check 0.0000 100 200 110 200
check 0.0000 100 200 110 199
check 100.0000 0 100 1000 200
check 0.0000 invalid 100 200 300
check 0.0000 100 invalid 200 300
# Verify the hot path calls the built-in calculation, not an AWK subprocess.
body="$(sed -n '/^_get_process_snapshot_unlocked() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total"' <<< "$body" || fail 'collector does not use the Bash calculation'
! grep -Fq 'system_load_pct="$(awk' <<< "$body" || fail 'AWK subprocess still calculates aggregate load'
echo 'Top Apps system load percent: OK'
