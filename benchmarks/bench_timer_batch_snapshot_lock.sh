#!/usr/bin/env bash
# Compare the former per-entry lock path with one lock for a complete daemon snapshot.
# Usage: benchmarks/bench_timer_batch_snapshot_lock.sh [iterations=100] [active_timers=8]
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
iterations="${1:-100}"
active="${2:-8}"
[[ "$iterations" =~ ^[0-9]+$ && "$iterations" -gt 0 ]] || { echo 'iterations must be positive' >&2; exit 2; }
[[ "$active" =~ ^[0-9]+$ && "$active" -gt 0 && "$active" -le 100 ]] || { echo 'active_timers must be 1..100' >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/daemon.sh"
timer_ensure_dirs
now="${EPOCHSECONDS:-$(date +%s)}"
files=()
for ((i=1; i<=active; i++)); do
    file="$TIMER_DIR/timer-$i"
    printf '30 %s 0 aabbcc 0 timer-%s\n' "$((now + 3600 + i))" "$i" > "$file"
    files+=("$file")
done
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
run_old() {
    local i file entry
    local -a entries=()
    for ((i=0; i<iterations; i++)); do
        entries=()
        for file in "${files[@]}"; do
            entry=''
            timer_process_entry_into entry "$file" "$now"
            [[ -n "$entry" ]] && entries+=("$entry")
        done
        timer_entries_to_json "${entries[@]}" >/dev/null
    done
}
run_new() {
    local i payload expirations
    for ((i=0; i<iterations; i++)); do
        payload=''; expirations=0
        timer_with_lock timer_process_batch_locked payload expirations "$now"
    done
}
old_times=(); new_times=()
for trial in 1 2 3 4 5; do
    clock_us start; run_old; clock_us finish; old_times+=("$((finish - start))")
    clock_us start; run_new; clock_us finish; new_times+=("$((finish - start))")
done
median_of old_times[@]; old_median="$REPLY"
median_of new_times[@]; new_median="$REPLY"
printf 'Timer daemon snapshot lock benchmark (%s timers, %s snapshots/trial, 5 trials)\n' "$active" "$iterations"
printf 'Before: flock launches=%d; median=%d.%03d ms\n' "$((active * iterations))" "$((old_median / 1000))" "$((old_median % 1000))"
printf 'After:  flock launches=%d; median=%d.%03d ms\n' "$iterations" "$((new_median / 1000))" "$((new_median % 1000))"
printf 'Lock subprocess reduction: %d -> %d per %d-timer snapshot (%d%% fewer)\n' "$active" 1 "$active" "$(((active - 1) * 100 / active))"
if (( old_median > 0 )); then
    reduction_tenths=$(((old_median - new_median) * 1000 / old_median))
    printf 'Median time reduction: %d.%d%%\n' "$((reduction_tenths / 10))" "$((reduction_tenths % 10))"
fi
