#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# Keep exactly the existing formatter's output, including odd negative edge
# values, so this optimization cannot subtly change daemon JSON.
for seconds in 0 1 59 60 61 3599 3600 3601 86399 86400 90061 604800 2147483647 -1 -61 -3601; do
    expected=$(format_time "$seconds")
    actual='__unset__'
    format_time_into actual "$seconds"
    [[ "$actual" == "$expected" ]] || fail "format mismatch for $seconds: expected <$expected>, got <$actual>"
done

# Verify the values are assigned to a caller-local variable, not a global-only
# value or a printed stdout result.
assign_in_scope() {
    local timer_display='' elapsed_display=''
    format_time_into timer_display 65
    format_time_into elapsed_display 3600
    [[ "$timer_display" == '01:05' && "$elapsed_display" == '01:00:00' ]]
}
assign_in_scope || fail 'format_time_into did not assign into caller scope'

if grep -Fq 'timer_str=$(format_time' "$ROOT/scripts/timer.d/daemon.sh"; then
    fail 'daemon still uses command substitution for remaining timer formatting'
fi
if grep -Fq 'time_passed=$(format_time' "$ROOT/scripts/timer.d/daemon.sh"; then
    fail 'daemon still uses command substitution for elapsed timer formatting'
fi
grep -Fq 'format_time_into timer_str' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon does not assign remaining time inline'
grep -Fq 'format_time_into time_passed' "$ROOT/scripts/timer.d/daemon.sh" || fail 'daemon does not assign elapsed time inline'

printf 'Timer format assignment parity and no-substitution path: OK\n'
