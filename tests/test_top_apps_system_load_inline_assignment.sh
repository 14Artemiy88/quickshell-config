#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps system load inline assignment: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

# Keep the old stdout API and the new direct-assignment API byte-identical.
cases=(
    '100 1000 1100 2000'
    '2000 3000 2250 3500'
    '0 0 1 3'
    '100 100 99 101'
    '100 200 110 200'
    '100 200 110 199'
    '0 100 1000 200'
    'invalid 100 200 300'
    '100 invalid 200 300'
    '000100 0001000 0001100 0002000'
    '1 2 999999999 1000000000'
)
for args in "${cases[@]}"; do
    read -r previous_busy previous_total current_busy current_total <<< "$args"
    expected="$(calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total")"
    actual='not-set'
    calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total" actual
    [[ "$actual" == "$expected" ]] || fail "direct assignment differs for [$args]: expected [$expected], got [$actual]"
    result='also-not-set'
    calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total" result
    [[ "$result" == "$expected" ]] || fail "assignment to variable named result differs for [$args]: expected [$expected], got [$result]"
done

body="$(sed -n '/^_get_process_snapshot_unlocked() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'calculate_system_load_percent "$previous_busy" "$previous_total" "$current_busy" "$current_total" system_load_pct' <<< "$body" || fail 'collector does not assign into system_load_pct directly'
! grep -Fq 'system_load_pct="$(calculate_system_load_percent' <<< "$body" || fail 'collector still creates a command-substitution subshell'

echo 'Top Apps system load inline assignment: OK'
