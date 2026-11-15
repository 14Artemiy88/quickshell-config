#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"
fail() { printf 'timer random color range test failed: %s\n' "$1" >&2; exit 1; }

check_range() {
    local mode="$1" min="$2" max="$3" lower="$4" upper="$5" sample i r g b
    for ((i=0; i<80; i++)); do
        sample=$(get_color "$mode" "$min" "$max")
        [[ "$sample" =~ ^[0-9a-f]{6}$ ]] || fail "$mode generated malformed color: $sample"
        r=$((16#${sample:0:2}))
        g=$((16#${sample:2:2}))
        b=$((16#${sample:4:2}))
        for channel in "$r" "$g" "$b"; do
            (( channel >= lower && channel <= upper )) || fail "$mode generated channel $channel outside $lower..$upper ($sample)"
        done
    done
}

check_range full '#000000' '#ffffff' 0 255
check_range light '#000000' '#ffffff' 128 255
check_range dark '#000000' '#ffffff' 0 127

# Custom endpoints are sampled independently per RGB channel, including when
# users provide the endpoints in reverse order.
for endpoints in '#123456 #789abc' '#f0e0d0 #102030'; do
    read -r min max <<< "$endpoints"
    sample=$(get_color custom "$min" "$max")
    for index in 0 2 4; do
        min_channel=$((16#${min:1+index:2}))
        max_channel=$((16#${max:1+index:2}))
        low=$min_channel; high=$max_channel
        (( low <= high )) || { low=$max_channel; high=$min_channel; }
        actual=$((16#${sample:index:2}))
        (( actual >= low && actual <= high )) || fail "custom range $min..$max generated $sample"
    done
done

echo 'Timer random color full/light/dark/custom ranges: OK'
