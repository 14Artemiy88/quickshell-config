#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU stats formula: FAIL: $*" >&2; exit 1; }
helper="$ROOT/scripts/cpu_stats.d/common.sh"
[[ -f "$helper" ]] || fail "shared CPU counter helper is missing"
source "$helper"

fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT
# guest and guest_nice are already included in user/nice and must not be
# counted twice. IRQ, softIRQ and steal time must be part of busy time.
cat > "$fixture" <<'STAT'
cpu 10000 1000 5000 30000 1000 200 300 100 2500 400
cpu0 100 20 30 400 10 5 5 2 50 3
STAT
actual="$(cpu_read_counters "$fixture")"
[[ "$actual" == "162 572" ]] || fail "expected busy/total 162 572, got: $actual"
named="$(cpu_read_counters_with_ids "$fixture")"
[[ "$named" == "cpu0 162 572" ]] || fail "named reader lost logical CPU id or changed counters: $named"
aggregate="$(cpu_read_aggregate_counters "$fixture")"
[[ "$aggregate" == "16600 47600" ]] || fail "expected aggregate busy/total 16600 47600, got: $aggregate"

[[ "$(cpu_usage_percent 100 200 125 250)" == "50" ]] || fail "normal delta should yield 50%"
[[ "$(cpu_usage_percent 100 200 300 300)" == "100" ]] || fail "percentage should clamp at 100"
[[ "$(cpu_usage_percent 100 200 100 200)" == "0" ]] || fail "no delta should yield 0%"
[[ "$(cpu_usage_percent 100 200 90 190)" == "0" ]] || fail "counter reset should yield 0%"

before_snapshot=$'cpu0 100 200\ncpu1 200 400\ncpu2 300 500'
# Deliberately change row order, remove cpu1 and add cpu3. Each existing core
# must be matched by id, not by the row's position in /proc/stat.
after_snapshot=$'cpu2 315 520\ncpu0 120 240\ncpu3 5 1005'
matched="$(cpu_usage_snapshot_percentages "$before_snapshot" "$after_snapshot")"
expected=$'cpu2 75\ncpu0 50\ncpu3 0'
[[ "$matched" == "$expected" ]] || fail "CPU-id matching failed across reorder/hotplug: $matched"
reset_match="$(cpu_usage_snapshot_percentages 'cpu0 100 200' 'cpu0 90 190')"
[[ "$reset_match" == "cpu0 0" ]] || fail "counter reset was not safely zeroed: $reset_match"

# Malformed per-core counters should be ignored, not interpreted as arithmetic.
bad_fixture="$(mktemp)"
trap 'rm -f "$fixture" "$bad_fixture"' EXIT
cat > "$bad_fixture" <<'STAT'
cpu0 10 0 10 70 5 0 0 0 0 0
cpu1 bad 0 10 70 5 0 0 0 0 0
STAT
[[ "$(cpu_read_counters_with_ids "$bad_fixture")" == "cpu0 20 95" ]] || fail "malformed per-core counters were not ignored"

# The first four values (user, nice, system, idle) are mandatory. A truncated
# row must be rejected rather than defaulting missing mandatory values to 0.
partial_fixture="$(mktemp)"
trap 'rm -f "$fixture" "$bad_fixture" "$partial_fixture"' EXIT
cat > "$partial_fixture" <<'STAT'
cpu 100
cpu0 100
STAT
[[ -z "$(cpu_read_counters_with_ids "$partial_fixture")" ]] || fail "truncated per-core rows were accepted"
[[ -z "$(cpu_read_aggregate_counters "$partial_fixture")" ]] || fail "truncated aggregate row was accepted"

# Older proc formats can omit optional counters after idle; those rows remain
# supported as long as the mandatory four counters are present.
cat > "$partial_fixture" <<'STAT'
cpu 100 0 100 700
cpu0 10 0 10 70
STAT
[[ "$(cpu_read_counters_with_ids "$partial_fixture")" == "cpu0 20 90" ]] || fail "valid legacy per-core row without optional counters was rejected"
[[ "$(cpu_read_aggregate_counters "$partial_fixture")" == "200 900" ]] || fail "valid legacy aggregate row without optional counters was rejected"

for script in "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; do
    grep -Fq 'cpu_stats.d/common.sh' "$script" || fail "$(basename "$script") doesn't use shared counters"
    grep -Fq 'cpu_read_counters_with_ids' "$script" || fail "$(basename "$script") does not retain logical CPU IDs"
    grep -Fq 'cpu_usage_snapshot_percentages' "$script" || fail "$(basename "$script") does not match snapshots by CPU ID"
done
if grep -Eq 'guest\+guest_nice|user\+nice\+system\)' "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; then
    fail "old CPU formula remains in a consumer script"
fi

echo "CPU stats formula: OK"
