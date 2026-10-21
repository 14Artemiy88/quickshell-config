#!/usr/bin/env bash
# Isolated microbenchmark for the clock-read operation used once per timer-daemon tick.
# Usage: benchmarks/bench_timer_clock_fastpath.sh [iterations=2000] [trials=5]
set -euo pipefail
iterations="${1:-2000}"
trials="${2:-5}"
[[ "$iterations" =~ ^[0-9]+$ && "$iterations" -gt 0 ]] || { echo 'iterations must be a positive integer' >&2; exit 2; }
[[ "$trials" =~ ^[0-9]+$ && "$trials" -gt 0 ]] || { echo 'trials must be a positive integer' >&2; exit 2; }

printf 'method,trial,iterations,elapsed_us,external_date_processes\n'
for ((trial=1; trial<=trials; trial++)); do
    # Match v715: one command substitution that starts `date` on every tick.
    local_start="${EPOCHREALTIME/./}"
    for ((i=0; i<iterations; i++)); do now="$(date '+%s')"; done
    local_end="${EPOCHREALTIME/./}"
    printf 'before_date,%d,%d,%d,%d\n' "$trial" "$iterations" "$((local_end-local_start))" "$iterations"

    # Match v716: Bash's EPOCHSECONDS variable, with no command substitution.
    local_start="${EPOCHREALTIME/./}"
    for ((i=0; i<iterations; i++)); do now="$EPOCHSECONDS"; done
    local_end="${EPOCHREALTIME/./}"
    printf 'after_epochseconds,%d,%d,%d,0\n' "$trial" "$iterations" "$((local_end-local_start))"
done
