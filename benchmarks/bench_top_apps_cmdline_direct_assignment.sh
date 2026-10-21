#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
iterations="${1:-1000}"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || { echo 'usage: bench_top_apps_cmdline_direct_assignment.sh [iterations]' >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cmdline_file="$work/cmdline"
printf '%s\0' '/opt/jetbrains/PhpStorm/jbr/bin/java' '-Didea.paths.selector=PhpStorm2025.1' 'com.intellij.idea.Main' '--bench-flag=value' > "$cmdline_file"

now_microseconds() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}

measure() {
    local label="$1" start end elapsed i value=''
    start="$(now_microseconds)"
    if [[ "$label" == stdout-capture ]]; then
        for ((i=0; i<iterations; i++)); do
            value="$(read_process_cmdline "$cmdline_file")"
            [[ "$value" == *'PhpStorm2025.1'* ]] || { echo 'unexpected cmdline result' >&2; return 1; }
        done
    else
        for ((i=0; i<iterations; i++)); do
            read_process_cmdline "$cmdline_file" value
            [[ "$value" == *'PhpStorm2025.1'* ]] || { echo 'unexpected cmdline result' >&2; return 1; }
        done
    fi
    end="$(now_microseconds)"
    elapsed=$((end - start))
    printf '%s iterations=%s subshells=%s elapsed_ms=%d.%03d\n' \
        "$label" "$iterations" "$([[ "$label" == stdout-capture ]] && printf '%s' "$iterations" || printf '0')" \
        "$((elapsed / 1000))" "$((elapsed % 1000))"
}

measure stdout-capture
measure direct-assignment
