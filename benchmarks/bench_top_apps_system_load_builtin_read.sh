#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$XDG_RUNTIME_DIR"
state_file="$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"
printf 'T\t1200\nC\t100\nS\t98765\t123456\nL\t42.2500\nP\t42\t100\t300\n' > "$state_file"
iterations="${1:-100}"

old_read() {
    awk -F '\t' '$1 == "L" && $2 ~ /^[0-9]+([.][0-9]+)?$/ { value=$2; found=1; exit } END { if (found) { if (value < 0) value=0; if (value > 100) value=100; printf "%.4f\n", value } else print "0.0000" }' "$state_file"
}

now_microseconds() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}

measure() {
    local label="$1" start end elapsed i value
    start="$(now_microseconds)"
    for ((i=0; i<iterations; i++)); do
        if [[ "$label" == old ]]; then value="$(old_read)"; else value="$(get_system_cpu_load_percent)"; fi
        [[ "$value" == '42.2500' ]] || { echo "bad result for $label: $value" >&2; return 1; }
    done
    end="$(now_microseconds)"
    elapsed=$((end - start))
    printf '%s %d\n' "$label" "$elapsed"
}

# Keep this benchmark concise: it compares the old per-read AWK parser with the
# built-in function on the same state file and returns microseconds.
measure old
measure new
