#!/usr/bin/env bash
# Compare the CPU graph's former command-substitution sample reader with the
# direct-assignment reader used by the daemon. This models parser/helper cost;
# it does not measure Quickshell rendering or filesystem publication.
# Usage: benchmarks/bench_cpu_graph_sample_inline_assignment.sh [samples=1000] [trials=5]
set -euo pipefail
samples="${1:-1000}"
trials="${2:-5}"
[[ "$samples" =~ ^[0-9]+$ && "$samples" -gt 0 ]] || { echo 'samples must be positive' >&2; exit 2; }
[[ "$trials" =~ ^[0-9]+$ && "$trials" -gt 0 ]] || { echo 'trials must be positive' >&2; exit 2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/cpu_stats.d/common.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
stat_file="$work/proc-stat"
cat > "$stat_file" <<'STAT'
cpu 10000 500 1500 25000 300 60 90 20 800 100
cpu0 100 5 20 300 10 2 3 1 20 2
cpu1 400 10 40 500 20 4 6 2 40 4
STAT

measure_old() {
  local counters i start end
  start="${EPOCHREALTIME/./}"
  for ((i=0; i<samples; i++)); do
    counters="$(cpu_read_aggregate_counters "$stat_file" 2>/dev/null || true)"
    [[ -n "$counters" ]] || return 1
  done
  end="${EPOCHREALTIME/./}"
  printf '%s\n' "$(((end-start)/1000))"
}
measure_new() {
  local counters i start end
  start="${EPOCHREALTIME/./}"
  for ((i=0; i<samples; i++)); do
    counters=''
    cpu_read_aggregate_counters_into counters "$stat_file" 2>/dev/null || counters=''
    [[ -n "$counters" ]] || return 1
  done
  end="${EPOCHREALTIME/./}"
  printf '%s\n' "$(((end-start)/1000))"
}
median() {
  local mode="$1" i
  local -a values=()
  for ((i=0; i<trials; i++)); do
    if [[ "$mode" == old ]]; then values+=("$(measure_old)"); else values+=("$(measure_new)"); fi
  done
  printf '%s\n' "${values[@]}" | sort -n | sed -n "$(((trials+1)/2))p"
}
old_ms="$(median old)"
new_ms="$(median new)"
printf 'CPU graph aggregate sample read (%s samples; median of %s trials):\n' "$samples" "$trials"
printf 'Before: %s command-substitution subshells, %s ms\n' "$samples" "$old_ms"
printf 'After:  0 command-substitution subshells, %s ms\n' "$new_ms"
if (( old_ms > 0 )); then
  printf 'Elapsed-time reduction in this fixture-backed helper loop: %.1f%%\n'     "$(awk -v old="$old_ms" -v new="$new_ms" 'BEGIN { printf "%.1f", (old-new)*100/old }')"
fi
