#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps CPU delta sampling: FAIL: $*" >&2; exit 1; }
source_script="$ROOT/scripts/system_monitor.d/top_apps.sh"
[[ -f "$source_script" ]] || fail "top_apps.sh is missing"
source "$source_script"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
previous="$workdir/previous.tsv"
current="$workdir/current.tsv"

# One second elapsed at CLK_TCK=100; 50 ticks on a stable PID means 50% of one core.
# A reused PID from before the interval stays at 0. A new process that started
# during this interval can account for its own CPU ticks on its first sample.
printf 'T\t1000\nP\t42\t999\t500\nP\t43\t200\t400\nP\t44\t300\t700\n' > "$previous"
printf 'worker\t550\t1024\t42\t1\t999\nreused\t900\t2048\t43\t1\t201\nnewproc\t90\t256\t45\t1\t500\nfresh\t30\t256\t46\t1\t1050\nreset\t600\t512\t44\t1\t300\n' > "$current"

rows="$(calculate_process_cpu_snapshot "$previous" "$current" 1100 100)" || fail "calculator returned failure"
worker="$(printf '%s\n' "$rows" | awk -F '\t' '$1 == "worker" {print $2}')"
[[ "$worker" == "50.0000" ]] || fail "expected 50.0000% for worker, got '${worker:-missing}'"
for name in reused newproc; do
    value="$(printf '%s\n' "$rows" | awk -F '\t' -v n="$name" '$1 == n {print $2}')"
    [[ "$value" == "0.0000" ]] || fail "$name should be zero because its start predates the current sample, got '${value:-missing}'"
done
fresh="$(printf '%s\n' "$rows" | awk -F '\t' '$1 == "fresh" {print $2}')"
[[ "$fresh" == "30.0000" ]] || fail "new process started during the interval should contribute its first-sample CPU, got '${fresh:-missing}'"

# A counter rollback (e.g. process replacement or invalid sample) must not produce negative CPU.
reset="$(printf '%s\n' "$rows" | awk -F '\t' '$1 == "reset" {print $2}')"
[[ "$reset" == "0.0000" ]] || fail "counter rollback should result in 0.0000%, got '${reset:-missing}'"

# CPU ranking omits groups with no measurable use; memory ranking still includes them.
fixture=$'ps\t0.0000\t100\t10\t1\nworker\t50.0000\t1024\t42\t1\nidle\t0.0000\t5000\t11\t1'
cpu_groups="$(printf '%s\n' "$fixture" | aggregate_process_rows cpu)"
mem_groups="$(printf '%s\n' "$fixture" | aggregate_process_rows mem)"
if printf '%s\n' "$cpu_groups" | grep -q '^ps\>'; then fail "zero-use ps process remains in CPU ranking"; fi
if printf '%s\n' "$cpu_groups" | grep -q '^idle\>'; then fail "zero-use process remains in CPU ranking"; fi
printf '%s\n' "$mem_groups" | grep -q '^ps\>' || fail "memory list should still include low-RAM processes"

# Confirm the live snapshot does not use ps's lifetime-average %CPU field.
if grep -Eq 'ps --no-header -eo[^\n]*pcpu' "$source_script"; then
    fail "producer still reads the lifetime-average CPU field from ps"
fi
grep -Fq 'utime stime' "$source_script" || fail "producer does not read per-PID CPU ticks"
grep -Fq 'starttime' "$source_script" || fail "PID reuse protection is missing"

echo "Top Apps CPU delta sampling: OK"
