#!/usr/bin/env bash
set -euo pipefail
rounds="${1:-100}"
[[ "$rounds" =~ ^[0-9]+$ ]] && (( rounds > 0 )) || { echo 'usage: bench_network_connections_inline_status.sh [refreshes]' >&2; exit 2; }

# Model the hot per-row status assignment for five connections during each
# cache refresh. It deliberately isolates that operation, not nmcli/JSON cost.
devices=(wlp2s0 enp2s0 '' wg0 '')
measure_before() {
    local i device status start end
    start=$(date +%s%N)
    for ((i=0; i<rounds; i++)); do
        for device in "${devices[@]}"; do
            status=$([[ -n "$device" ]] && printf 'on' || printf 'off')
        done
    done
    end=$(date +%s%N)
    printf '%s\n' "$(((end-start)/1000))"
}
measure_after() {
    local i device status start end
    start=$(date +%s%N)
    for ((i=0; i<rounds; i++)); do
        for device in "${devices[@]}"; do
            if [[ -n "$device" ]]; then status=on; else status=off; fi
        done
    done
    end=$(date +%s%N)
    printf '%s\n' "$(((end-start)/1000))"
}
median_us() {
    local mode="$1" i
    local -a values=()
    for ((i=0; i<5; i++)); do
        if [[ "$mode" == before ]]; then values+=("$(measure_before)"); else values+=("$(measure_after)"); fi
    done
    printf '%s\n' "${values[@]}" | sort -n | sed -n '3p'
}
before_us="$(median_us before)"
after_us="$(median_us after)"
rows=$((rounds * ${#devices[@]}))
printf 'Network connection status assignment (%s refreshes x %s rows; median of 5): before=%d.%03d ms, after=%d.%03d ms\n' \
    "$rounds" "${#devices[@]}" "$((before_us/1000))" "$((before_us%1000))" "$((after_us/1000))" "$((after_us%1000))"
printf 'Command-substitution subshells modeled in status assignment: before=%d, after=0\n' "$rows"
