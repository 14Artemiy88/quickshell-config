#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps aggregate CPU counter inline assignment: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
fixture="$(mktemp)"
invalid="$(mktemp)"
trap 'rm -f "$fixture" "$invalid"' EXIT
cat > "$fixture" <<'STAT'
cpu 1000 200 300 4000 20 30 40 10 5 2
cpu0 100 0 10 900
STAT
expected="$(cpu_read_aggregate_counters "$fixture")"
actual='unset'
cpu_read_aggregate_counters_into actual "$fixture" || fail 'direct aggregate counter read failed'
[[ "$actual" == "$expected" ]] || fail "direct API differs: expected [$expected], got [$actual]"
[[ "$actual" == '1580 5600' ]] || fail "unexpected aggregate counters: $actual"

# The optional counters can be omitted on old proc formats.
printf 'cpu 100 0 100 700\ncpu0 10 0 10 70\n' > "$fixture"
expected="$(cpu_read_aggregate_counters "$fixture")"
cpu_read_aggregate_counters_into actual "$fixture" || fail 'legacy aggregate counters rejected'
[[ "$actual" == "$expected" && "$actual" == '200 900' ]] || fail "legacy counters differ: $actual"

# Invalid snapshots must clear the destination and retain a failure status.
printf 'cpu 100\ncpu0 10 0\n' > "$invalid"
actual='stale-value'
if cpu_read_aggregate_counters_into actual "$invalid"; then
    fail 'truncated aggregate line was accepted'
fi
[[ -z "$actual" ]] || fail "invalid input left stale output [$actual]"

body="$(sed -n '/^_get_process_snapshot_unlocked() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'cpu_read_aggregate_counters_into system_counters "$proc_stat_path"' <<< "$body" || fail 'Top Apps does not use direct aggregate counter assignment'
! grep -Fq 'system_counters="$(cpu_read_aggregate_counters' <<< "$body" || fail 'Top Apps still captures aggregate counters through command substitution'

echo 'Top Apps aggregate CPU counter inline assignment: OK'
