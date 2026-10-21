#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"

# The former stdout-oriented implementation, kept here only for comparison.
json_escape_legacy() {
    local LC_ALL=C
    local value="$1" char escaped out="" i code
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            $'\\') out+='\\' ;;
            '"') out+='\"' ;;
            $'\b') out+='\b' ;;
            $'\f') out+='\f' ;;
            $'\n') out+='\n' ;;
            $'\r') out+='\r' ;;
            $'\t') out+='\t' ;;
            *)
                printf -v code '%d' "'$char"
                if (( code < 32 || code == 127 )); then
                    printf -v escaped '\\u%04x' "$code"
                    out+="$escaped"
                else
                    out+="$char"
                fi
                ;;
        esac
    done
    printf '%s' "$out"
}

clock_us() {
    local output_var="$1" raw="$EPOCHREALTIME" sec frac
    sec="${raw%.*}"
    frac="${raw#*.}000000"
    frac="${frac:0:6}"
    printf -v "$output_var" '%d' "$((sec * 1000000 + 10#$frac))"
}

measure_before() {
    local escaped_comment escaped_file i
    for ((i = 0; i < 200; i++)); do
        escaped_comment=$(json_escape_legacy "$comment")
        escaped_file=$(json_escape_legacy "$file_path")
    done
}

measure_after() {
    local escaped_comment escaped_file i
    for ((i = 0; i < 200; i++)); do
        json_escape_into escaped_comment "$comment"
        json_escape_into escaped_file "$file_path"
    done
}

comment=$'Timer note: "focus" \\ track\nследующая часть 🎵'
file_path='/run/user/1000/timer/Таймер "name" with spaces'
before_ms=()
after_ms=()
for trial in 1 2 3 4 5; do
    clock_us start
    measure_before
    clock_us finish
    before_ms+=( "$((finish - start))" )
    clock_us start
    measure_after
    clock_us finish
    after_ms+=( "$((finish - start))" )
done
median_us() { printf '%s\n' "$@" | sort -n | sed -n '3p'; }
printf 'Timer-entry JSON escaping microbenchmark (200 mock entries, 5 trials)\n'
printf 'Before, microseconds: %s\n' "${before_ms[*]}"
printf 'After, microseconds:  %s\n' "${after_ms[*]}"
before_median=$(median_us "${before_ms[@]}")
after_median=$(median_us "${after_ms[@]}")
printf 'Median before: %d.%03d ms\n' "$((before_median / 1000))" "$((before_median % 1000))"
printf 'Median after:  %d.%03d ms\n' "$((after_median / 1000))" "$((after_median % 1000))"
printf 'Command-substitution subshells per 200 entries: 400 -> 0\n'
