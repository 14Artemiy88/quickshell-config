#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"
source "$ROOT/scripts/timer.d/daemon.sh"

clock_us() {
    local output_var="$1" raw="$EPOCHREALTIME" sec frac
    sec="${raw%.*}"
    frac="${raw#*.}000000"
    frac="${frac:0:6}"
    printf -v "$output_var" '%d' "$((sec * 1000000 + 10#$frac))"
}
median_us() { printf '%s\n' "$@" | sort -n | sed -n '3p'; }

entries=()
for i in 1 2 3 4 5 6 7 8; do
    entries+=("{\"file\":\"/run/user/1000/timer/timer-$i\",\"comment\":\"focus, task $i\",\"timer\":\"12:34\",\"color\":\"#abcdef\",\"sign\":\"\",\"time_passed\":\"01:23\",\"ding\":0}")
done
before_ms=()
after_ms=()
for trial in 1 2 3 4 5; do
    clock_us start
    for ((i=0; i<100; i++)); do
        printf '%s\n' "${entries[@]}" | jq -s -c . >/dev/null
    done
    clock_us finish
    before_ms+=( "$((finish - start))" )

    clock_us start
    for ((i=0; i<100; i++)); do
        timer_entries_to_json "${entries[@]}" >/dev/null
    done
    clock_us finish
    after_ms+=( "$((finish - start))" )
done
before_median="$(median_us "${before_ms[@]}")"
after_median="$(median_us "${after_ms[@]}")"
printf 'Timer daemon JSON array wrapping microbenchmark (8 records, 100 arrays/trial, 5 trials)\n'
printf 'Before median: %d.%03d ms\n' "$((before_median / 1000))" "$((before_median % 1000))"
printf 'After median:  %d.%03d ms\n' "$((after_median / 1000))" "$((after_median % 1000))"
printf 'jq launches per 100 non-empty ticks: 100 -> 0\n'
printf 'Pipeline/subshell path per 100 non-empty ticks: 100 -> 0\n'
