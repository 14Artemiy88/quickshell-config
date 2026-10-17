#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/scripts/cpu_stats.d/common.sh"
fail() { echo "CPU snapshot subprocess regression: FAIL: $*" >&2; exit 1; }
[[ -f "$HELPER" ]] || fail "shared CPU helper is missing"

# cpu_usage_snapshot_percentages runs on every CPU-stat sample. Calculating a
# core's delta via command substitution starts a subshell for every logical
# CPU, so keep this function's hot loop inline. Functional parity for matching,
# reordered/hotplugged cores and resets is covered by test_cpu_stats_formula.sh.
function_body="$(sed -n '/^cpu_usage_snapshot_percentages() {/,/^}/p' "$HELPER")"
[[ -n "$function_body" ]] || fail "snapshot percentage function could not be read"
if grep -Fq '$(cpu_usage_percent ' <<< "$function_body"; then
  fail "per-core percentage still runs via command substitution"
fi

source "$HELPER"
before=$'cpu0 100 200\ncpu1 100 300\ncpu2 0 100'
after=$'cpu0 150 300\ncpu1 200 500\ncpu2 10 120'
actual="$(cpu_usage_snapshot_percentages "$before" "$after")"
expected=$'cpu0 50\ncpu1 50\ncpu2 50'
[[ "$actual" == "$expected" ]] || fail "inline calculation changed percentages: $actual"

reset="$(cpu_usage_snapshot_percentages 'cpu0 100 200' 'cpu0 90 190')"
[[ "$reset" == 'cpu0 0' ]] || fail "counter reset did not clamp to zero: $reset"

printf 'CPU snapshot subprocess regression: OK\n'
