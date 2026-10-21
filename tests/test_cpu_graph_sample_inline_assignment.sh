#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU graph inline sample assignment: FAIL: $*" >&2; exit 1; }
helper="$ROOT/scripts/cpu_stats.d/common.sh"
daemon="$ROOT/scripts/cpu_graph_daemon"
[[ -f "$helper" && -x "$daemon" ]] || fail "CPU helper or graph daemon is missing"
source "$helper"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
valid="$work/proc-stat-valid"
invalid="$work/proc-stat-invalid"
cat > "$valid" <<'STAT'
cpu 100 0 100 700 50 0 0 0 0 0
cpu0 10 0 10 70 5 0 0 0 0 0
STAT

expected="$(cpu_read_aggregate_counters "$valid")"
actual='stale'
cpu_read_aggregate_counters_into actual "$valid" || fail "direct aggregate read failed"
[[ "$actual" == "$expected" && "$actual" == '200 950' ]] ||   fail "inline helper mismatch: expected [$expected], got [$actual]"

cat > "$invalid" <<'STAT'
cpu 100
STAT
actual='stale'
if cpu_read_aggregate_counters_into actual "$invalid"; then
  fail "truncated aggregate sample was accepted"
fi
[[ -z "$actual" ]] || fail "invalid sample left stale caller output [$actual]"

body="$(sed -n '/^while true; do$/,/^    sleep "\$INTERVAL"$/p' "$daemon" | head -n 16)"
grep -Fq 'cpu_read_aggregate_counters_into counters "$PROC_STAT"' <<< "$body" ||   fail "daemon does not use direct caller-variable reader"
if grep -Eq 'counters=\$\(cpu_read_aggregate_counters([[:space:]]|\))' <<< "$body"; then
  fail "daemon still captures aggregate counters through command substitution"
fi
# Keep the old stdout API for existing shell callers; only the long-running
# daemon hot path should use the direct-assignment variant.
grep -Fq 'cpu_read_aggregate_counters()' "$helper" || fail "compatibility stdout reader was removed"

echo "CPU graph inline sample assignment: OK"
