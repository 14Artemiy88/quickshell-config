#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rounds="${1:-100}"
[[ "$rounds" =~ ^[0-9]+$ ]] && (( rounds > 0 )) || { echo 'usage: bench_cpu_sampling_inline_assignments.sh [rounds]' >&2; exit 2; }
source "$ROOT/scripts/cpu_stats.d/common.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
stat_file="$work/stat"
mem_file="$work/meminfo"
cat > "$stat_file" <<'STAT'
cpu 10000 500 1500 25000 300 60 90 20 800 100
cpu0 100 5 20 300 10 2 3 1 20 2
cpu2 400 10 40 500 20 4 6 2 40 4
STAT
cat > "$mem_file" <<'MEM'
MemTotal: 1000 kB
MemFree: 100 kB
MemAvailable: 300 kB
MEM

measure_old() {
    local baseline current pct ram i
    baseline="$(cpu_read_counters_with_ids "$stat_file")"
    local start end
    start=$(date +%s%N)
    for ((i=0; i<rounds; i++)); do
        current="$(cpu_read_counters_with_ids "$stat_file")"
        pct="$(cpu_usage_snapshot_percentages "$baseline" "$current")"
        ram="$(mem_usage_percent "$mem_file")"
        baseline="$current"
    done
    end=$(date +%s%N)
    printf '%s\n' "$(((end-start)/1000))"
}
measure_new() {
    local baseline current pct ram i start end
    cpu_read_counters_with_ids_into baseline "$stat_file"
    start=$(date +%s%N)
    for ((i=0; i<rounds; i++)); do
        cpu_read_counters_with_ids_into current "$stat_file"
        cpu_usage_snapshot_percentages_into pct "$baseline" "$current"
        mem_usage_percent_into ram "$mem_file"
        baseline="$current"
    done
    end=$(date +%s%N)
    printf '%s\n' "$(((end-start)/1000))"
}
median_us() {
    local mode="$1" i
    local -a values=()
    for ((i=0; i<5; i++)); do
        if [[ "$mode" == old ]]; then values+=("$(measure_old)"); else values+=("$(measure_new)"); fi
    done
    printf '%s\n' "${values[@]}" | sort -n | sed -n '3p'
}
old_us="$(median_us old)"
new_us="$(median_us new)"
printf 'CPU sampling (%s polls; median of 5): before=%d.%03d ms, after=%d.%03d ms\n' \
    "$rounds" "$((old_us/1000))" "$((old_us%1000))" "$((new_us/1000))" "$((new_us%1000))"
printf 'Command-substitution subshells in modeled persistent poll: before=%d, after=0\n' "$((rounds*3))"
printf 'Command-substitution subshells in modeled one-shot poll: before=%d, after=0\n' "$((rounds*4))"
