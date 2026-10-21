#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
iterations="${1:-1000}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_system_load_inline_assignment.sh [iterations]' >&2; exit 2; }

# Baseline emulates the pre-optimization caller: capture stdout on every sample.
start=$EPOCHREALTIME
for ((i=0; i<iterations; i++)); do
    result="$(calculate_system_load_percent 123456 200000 123990 200750)"
done
end=$EPOCHREALTIME
printf 'stdout-capture iterations=%s last=%s elapsed=%s\n' "$iterations" "$result" "$(awk -v a="$start" -v b="$end" 'BEGIN {printf "%.3f", (b-a)*1000}')"

# Optimized call writes into this scope directly and creates no command substitution.
start=$EPOCHREALTIME
for ((i=0; i<iterations; i++)); do
    calculate_system_load_percent 123456 200000 123990 200750 result
done
end=$EPOCHREALTIME
printf 'direct-assignment iterations=%s last=%s elapsed=%s\n' "$iterations" "$result" "$(awk -v a="$start" -v b="$end" 'BEGIN {printf "%.3f", (b-a)*1000}')"
