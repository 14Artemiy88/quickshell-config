#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
iterations="${1:-1000}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_capacity_inline_assignments.sh [iterations]' >&2; exit 2; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '0-3,8,10-13\n' > "$tmp/cpu-online"
printf 'MemTotal: 32768000 kB\nMemFree: 1000000 kB\n' > "$tmp/meminfo"
export TOP_APPS_CPU_ONLINE="$tmp/cpu-online" TOP_APPS_MEMINFO="$tmp/meminfo"

measure() {
    local mode="$1" start end cpu='' mem=''
    start="$EPOCHREALTIME"
    for ((i=0; i<iterations; i++)); do
        if [[ "$mode" == stdout ]]; then
            cpu="$(get_cpu_capacity_percent)"
            mem="$(get_total_memory_kib)"
        else
            get_cpu_capacity_percent cpu
            get_total_memory_kib mem
        fi
    done
    end="$EPOCHREALTIME"
    awk -v a="$start" -v b="$end" -v n="$iterations" -v cpu="$cpu" -v mem="$mem" -v mode="$mode" 'BEGIN { printf "%s iterations=%d cpu=%s mem=%s elapsed_ms=%.3f\n", mode, n, cpu, mem, (b-a)*1000 }'
}
measure stdout
measure direct
