#!/usr/bin/env bash
# Compare the old stdout/command-substitution call path with direct assignment.
# Reports concise medians only and writes no output files.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
timer_ensure_dirs
file="$TIMER_DIR/bench"
now="${EPOCHSECONDS:-$(date '+%s')}"
printf '20 %s 0 aabbcc 0 benchmark\n' "$((now + 3600))" > "$file"
ITERATIONS="${1:-100}"
TRIALS=5
[[ "$ITERATIONS" =~ ^[0-9]+$ && "$ITERATIONS" -gt 0 ]] || { echo 'usage: bench_timer_daemon_inline_entry.sh [iterations]' >&2; exit 2; }
clock_us() {
    local output_var="$1" raw="$EPOCHREALTIME" sec frac
    sec="${raw%.*}"
    frac="${raw#*.}000000"
    frac="${frac:0:6}"
    printf -v "$output_var" '%d' "$((sec * 1000000 + 10#$frac))"
}
median_of() {
    local -a sorted=() values=("${!1}")
    local value pos i
    for value in "${values[@]}"; do
        pos=${#sorted[@]}
        while (( pos > 0 && sorted[pos-1] > value )); do pos=$((pos - 1)); done
        sorted+=("$value")
        for ((i=${#sorted[@]}-1; i>pos; i--)); do sorted[i]="${sorted[i-1]}"; done
        sorted[pos]="$value"
    done
    REPLY="${sorted[${#sorted[@]}/2]}"
}
old_times=() new_times=()
run_old() {
    local i row
    for ((i=0; i<ITERATIONS; i++)); do row="$(timer_process_entry "$file" "$now")"; done
}
run_new() {
    local i row
    for ((i=0; i<ITERATIONS; i++)); do timer_process_entry_into row "$file" "$now"; done
}
measure() {
    local fn="$1" start finish
    clock_us start
    "$fn"
    clock_us finish
    REPLY=$((finish - start))
}
for ((trial=0; trial<TRIALS; trial++)); do
    measure run_old; old_times+=("$REPLY")
    measure run_new; new_times+=("$REPLY")
done
median_of old_times[@]; old_median=$REPLY
median_of new_times[@]; new_median=$REPLY
printf 'Timer entry processing: %s records/trial, %s trials\n' "$ITERATIONS" "$TRIALS"
printf 'before: %s command-substitution subshells; median %d.%03d ms\n' "$ITERATIONS" "$((old_median / 1000))" "$((old_median % 1000))"
printf 'after:  0 command-substitution subshells; median %d.%03d ms\n' "$((new_median / 1000))" "$((new_median % 1000))"
