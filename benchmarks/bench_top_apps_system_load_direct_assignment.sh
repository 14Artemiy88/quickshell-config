#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
iterations="${1:-1000}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_system_load_direct_assignment.sh [iterations]' >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export XDG_RUNTIME_DIR="$work/runtime"
mkdir -p "$XDG_RUNTIME_DIR"
printf 'T\t1200\nC\t100\nS\t98765\t123456\nL\t42.2500\nP\t42\t100\t300\n' > "$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"

now_microseconds() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}

measure() {
    local label="$1" start end elapsed i result='' load_value=''
    start="$(now_microseconds)"
    if [[ "$label" == stdout-capture ]]; then
        for ((i=0; i<iterations; i++)); do
            result="$(get_system_cpu_load_percent)"
            [[ "$result" == '42.2500' ]] || { echo "unexpected value: $result" >&2; return 1; }
        done
    else
        for ((i=0; i<iterations; i++)); do
            get_system_cpu_load_percent load_value
            [[ "$load_value" == '42.2500' ]] || { echo "unexpected value: $load_value" >&2; return 1; }
        done
        result="$load_value"
    fi
    end="$(now_microseconds)"
    elapsed=$((end - start))
    printf '%s iterations=%s subshells=%s elapsed_ms=%d.%03d\n' \
        "$label" "$iterations" "$([[ "$label" == stdout-capture ]] && printf '%s' "$iterations" || printf '0')" \
        "$((elapsed / 1000))" "$((elapsed % 1000))"
}

measure stdout-capture
measure direct-assignment
