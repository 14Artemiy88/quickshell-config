#!/usr/bin/env bash
# Compare two timer time-format values with the same old/new implementation
# used by timer.d/daemon.sh. Output only concise medians; no files are written.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"
ITERATIONS="${1:-200}"
TRIALS=5
[[ "$ITERATIONS" =~ ^[0-9]+$ && "$ITERATIONS" -gt 0 ]] || { echo 'usage: bench_timer_format_time_inline.sh [iterations]' >&2; exit 2; }

old_times=()
new_times=()
old_subshells=$((ITERATIONS * 2))
new_subshells=0

run_old() {
    local i a b
    for ((i=0; i<ITERATIONS; i++)); do
        a=$(format_time $((i * 17 + 65)))
        b=$(format_time $((i * 17 + 3600)))
    done
}
run_new() {
    local i a b
    for ((i=0; i<ITERATIONS; i++)); do
        format_time_into a $((i * 17 + 65))
        format_time_into b $((i * 17 + 3600))
    done
}
measure_us() {
    local start end
    start=${EPOCHREALTIME/./}
    "$1"
    end=${EPOCHREALTIME/./}
    REPLY=$((end - start))
}
median_of() {
    local -a values=("${!1}") sorted=()
    local value pos
    for value in "${values[@]}"; do
        pos=${#sorted[@]}
        while (( pos > 0 )) && (( sorted[pos-1] > value )); do
            pos=$((pos - 1))
        done
        sorted+=("$value")
        for ((i=${#sorted[@]}-1; i>pos; i--)); do sorted[i]="${sorted[i-1]}"; done
        sorted[pos]="$value"
    done
    REPLY="${sorted[${#sorted[@]}/2]}"
}

for ((trial=0; trial<TRIALS; trial++)); do
    measure_us run_old; old_times+=("$REPLY")
    measure_us run_new; new_times+=("$REPLY")
done
median_of old_times[@]; old_median=$REPLY
median_of new_times[@]; new_median=$REPLY
printf 'same work: %s iterations × 2 formats × %s trials (microseconds)\n' "$ITERATIONS" "$TRIALS"
printf 'before: %s command-substitution subshells/trial; median %s us\n' "$old_subshells" "$old_median"
printf 'after:  %s command-substitution subshells/trial; median %s us\n' "$new_subshells" "$new_median"
if (( new_median > 0 )); then
    ratio_tenths=$(((old_median * 10 + new_median / 2) / new_median))
    printf 'speedup of formatting path: %d.%dx\n' "$((ratio_tenths / 10))" "$((ratio_tenths % 10))"
fi
