#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
iterations="${1:-50}"
source_script="${2:-$ROOT/scripts/system_monitor.d/top_apps.sh}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_aggregate_sort_inline.sh [iterations] [top_apps.sh]' >&2; exit 2; }
[[ -r "$source_script" ]] || { echo "cannot read Top Apps script: $source_script" >&2; exit 2; }
source "$source_script"
aggregate_body="$(declare -f aggregate_process_rows)"
if grep -Fq 'LC_ALL=C sort -t' <<< "$aggregate_body"; then
    sort_calls_per_iteration=1
else
    sort_calls_per_iteration=0
fi

# Synthetic process snapshot: 360 processes fold into 113 application names,
# with deliberately repeated CPU values so both ordering and tie-break logic
# are exercised during the same aggregation workload used by Top Apps.
rows=''
for ((i=0; i<360; i++)); do
    name="app$(( (i * 37) % 113 ))"
    cpu_scaled=$(( (i * 137) % 997 ))
    (( i % 17 != 0 )) || cpu_scaled=2500
    printf -v cpu '%d.%04d' "$((cpu_scaled / 10000))" "$((cpu_scaled % 10000))"
    rss=$((1000 + (i * 7919) % 500000))
    pid=$((1000 + i))
    ppid=1
    rows+="$name"$'\t'"$cpu"$'\t'"$rss"$'\t'"$pid"$'\t'"$ppid"$'\n'
done

now_microseconds() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}

for run in 1 2 3 4 5; do
    start="$(now_microseconds)"
    for ((i=0; i<iterations; i++)); do
        printf '%s\n' "$rows" | aggregate_process_rows cpu 5 >/dev/null
    done
    end="$(now_microseconds)"
    elapsed=$((end - start))
    printf 'run=%d calls=%d external_sort_calls=%d elapsed_ms=%d.%03d\n' \
        "$run" "$iterations" "$((iterations * sort_calls_per_iteration))" \
        "$((elapsed / 1000))" "$((elapsed % 1000))"
done
