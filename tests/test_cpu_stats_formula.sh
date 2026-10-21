#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU stats formula: FAIL: $*" >&2; exit 1; }
helper="$ROOT/scripts/cpu_stats.d/common.sh"
[[ -f "$helper" ]] || fail "shared CPU counter helper is missing"
source "$helper"

fixture="$(mktemp)"
bad_fixture="$(mktemp)"
partial_fixture="$(mktemp)"
mem_fixture="$(mktemp)"
trap 'rm -f "$fixture" "$bad_fixture" "$partial_fixture" "$mem_fixture"' EXIT
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
[[ "$reset_match" == "cpu0 0" ]] || fail "counter reset was not safely zeroed"

# Caller-variable APIs must match the stable stdout interfaces exactly.
cpu_read_counters_with_ids_into named_into "$fixture" || fail "direct named snapshot read failed"
[[ "$named_into" == "$named" ]] || fail "direct named snapshot differs from stdout API"
cpu_usage_snapshot_percentages_into matched_into "$before_snapshot" "$after_snapshot"
[[ "$matched_into" == "$matched" ]] || fail "direct percentage snapshot differs from stdout API"
printf 'MemTotal: 1000 kB\nMemAvailable: 250 kB\n' > "$mem_fixture"
mem_old="$(mem_usage_percent "$mem_fixture")"
mem_usage_percent_into mem_new "$mem_fixture"
[[ "$mem_new" == "$mem_old" ]] || fail "direct memory percentage differs from stdout API"
[[ "$mem_new" == "75" ]] || fail "memory percentage should be 75, got $mem_new"

# Malformed per-core counters should be ignored, not interpreted as arithmetic.
cat > "$bad_fixture" <<'STAT'
cpu0 10 0 10 70 5 0 0 0 0 0
cpu1 bad 0 10 70 5 0 0 0 0 0
STAT
[[ "$(cpu_read_counters_with_ids "$bad_fixture")" == "cpu0 20 95" ]] || fail "malformed per-core counters were not ignored"
cpu_read_counters_with_ids_into named_into "$bad_fixture"
[[ "$named_into" == 'cpu0 20 95' ]] || fail "direct parser did not skip malformed CPU rows"

# The first four values (user, nice, system, idle) are mandatory.
cat > "$partial_fixture" <<'STAT'
cpu 100
cpu0 100
STAT
[[ -z "$(cpu_read_counters_with_ids "$partial_fixture")" ]] || fail "truncated per-core rows were accepted"
[[ -z "$(cpu_read_aggregate_counters "$partial_fixture")" ]] || fail "truncated aggregate row was accepted"
cpu_read_counters_with_ids_into named_into "$partial_fixture"
[[ -z "$named_into" ]] || fail "direct parser accepted truncated per-core rows"

# Older proc formats can omit optional counters after idle.
cat > "$partial_fixture" <<'STAT'
cpu 100 0 100 700
cpu0 10 0 10 70
STAT
[[ "$(cpu_read_counters_with_ids "$partial_fixture")" == "cpu0 20 90" ]] || fail "valid legacy per-core row without optional counters was rejected"
[[ "$(cpu_read_aggregate_counters "$partial_fixture")" == "200 900" ]] || fail "valid legacy aggregate row without optional counters was rejected"
cpu_read_counters_with_ids_into named_into "$partial_fixture"
[[ "$named_into" == 'cpu0 20 90' ]] || fail "direct parser rejected valid legacy row"

for script in "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; do
    grep -Fq 'cpu_stats.d/common.sh' "$script" || fail "$(basename "$script") doesn't use shared counters"
    grep -Fq 'cpu_read_counters_with_ids_into' "$script" || fail "$(basename "$script") does not use direct counter assignments"
    grep -Fq 'cpu_usage_snapshot_percentages_into' "$script" || fail "$(basename "$script") does not use direct percentage assignment"
    grep -Fq 'mem_usage_percent_into' "$script" || fail "$(basename "$script") does not use direct memory assignment"
done
if grep -Eq '=\$\((cpu_read_counters_with_ids|cpu_usage_snapshot_percentages|mem_usage_percent) ' "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; then
    fail "CPU consumer still captures hot-path helper output through command substitution"
fi
if grep -Eq 'guest\+guest_nice|user\+nice\+system\)' "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once"; then
    fail "old CPU formula remains in a consumer script"
fi

echo "CPU stats formula: OK"
