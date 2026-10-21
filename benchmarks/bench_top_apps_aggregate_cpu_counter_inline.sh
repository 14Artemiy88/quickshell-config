#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/cpu_stats.d/common.sh"
iterations="${1:-1000}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_aggregate_cpu_counter_inline.sh [iterations]' >&2; exit 2; }
fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT
cat > "$fixture" <<'STAT'
cpu 1000 200 300 4000 20 30 40 10 5 2
cpu0 100 0 10 900
STAT

start=$EPOCHREALTIME
for ((i=0; i<iterations; i++)); do
    result="$(cpu_read_aggregate_counters "$fixture")"
done
end=$EPOCHREALTIME
baseline_ms="$(awk -v a="$start" -v b="$end" 'BEGIN {printf "%.3f", (b-a)*1000}')"
printf 'stdout-capture iterations=%s last=%s elapsed_ms=%s\n' "$iterations" "$result" "$baseline_ms"

start=$EPOCHREALTIME
for ((i=0; i<iterations; i++)); do
    cpu_read_aggregate_counters_into result "$fixture"
done
end=$EPOCHREALTIME
direct_ms="$(awk -v a="$start" -v b="$end" 'BEGIN {printf "%.3f", (b-a)*1000}')"
printf 'direct-assignment iterations=%s last=%s elapsed_ms=%s\n' "$iterations" "$result" "$direct_ms"
