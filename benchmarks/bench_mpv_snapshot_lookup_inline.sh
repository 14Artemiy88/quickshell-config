#!/usr/bin/env bash
# Compare stdout/command-substitution lookup with direct caller-variable lookup.
# Outputs only concise medians; no CSV/graph files are written.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="${1:-500}"
TRIALS=5
[[ "$ITERATIONS" =~ ^[0-9]+$ && "$ITERATIONS" -gt 0 ]] || {
    echo 'usage: bench_mpv_snapshot_lookup_inline.sh [iterations]' >&2; exit 2;
}
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_RUNTIME_DIR="$TMP/runtime"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
export XDG_STATE_HOME="$TMP/state"
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
source "$ROOT/scripts/player.d/common.sh"
source_path='/bench/track with spaces.mkv'
mpv_snapshot_key_into "$source_path" key
snapshot_name="mpv-${key}-1760102030123456789.png"
mkdir -p "$IMG_PATH"
printf 'cached frame\n' > "$IMG_PATH/$snapshot_name"
mpv_store_latest_snapshot_for_key "$key" "$snapshot_name"

old_times=()
new_times=()
run_old() {
    local i result lookup_key
    for ((i=0; i<ITERATIONS; i++)); do
        lookup_key="$(mpv_snapshot_key "$source_path")"
        result="$(mpv_latest_snapshot_for_key "$lookup_key")"
    done
}
run_new() {
    local i result lookup_key
    for ((i=0; i<ITERATIONS; i++)); do
        mpv_snapshot_key_into "$source_path" lookup_key
        mpv_latest_snapshot_for_key_into "$lookup_key" result
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
    local value pos i
    for value in "${values[@]}"; do
        pos=${#sorted[@]}
        while (( pos > 0 )) && (( sorted[pos-1] > value )); do pos=$((pos - 1)); done
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
printf 'same work: %s source-key + cache-hit lookup pairs × %s trials (microseconds)\n' "$ITERATIONS" "$TRIALS"
printf 'before: %s command-substitution subshells/trial; median %s us\n' "$((ITERATIONS * 3))" "$old_median"
printf 'after:  %s command-substitution subshells/trial; median %s us\n' "$ITERATIONS" "$new_median"
if (( new_median > 0 )); then
    ratio_tenths=$(((old_median * 10 + new_median / 2) / new_median))
    printf 'speedup of lookup-call path: %d.%dx\n' "$((ratio_tenths / 10))" "$((ratio_tenths % 10))"
fi
