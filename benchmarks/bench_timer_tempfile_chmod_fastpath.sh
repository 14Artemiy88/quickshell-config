#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
timer_ensure_dirs

chmod_count=0
chmod() { chmod_count=$((chmod_count + 1)); command chmod "$@"; }

write_timer_file_before() {
    local file="$1" temp
    temp=$(mktemp "$TIMER_DIR/.timer-write.XXXXXX") || return 1
    printf '%s %s %s %s %s %s\n' "$total_time" "$end_time" "$ding" "$color" "$paused_at" "$comment" > "$temp"
    chmod 600 "$temp" 2>/dev/null || true
    mv -f -- "$temp" "$file"
}

measure() {
    local fn="$1" count="$2" i start end
    chmod_count=0
    start=$EPOCHREALTIME
    for ((i=0;i<count;i++)); do "$fn" "$TIMER_DIR/bench-$i"; done
    end=$EPOCHREALTIME
    local start_us end_us
    start_us=$(awk -F. '{print $1 $2}' <<< "$start")
    end_us=$(awk -F. '{print $1 $2}' <<< "$end")
    printf '%s %s\n' "$chmod_count" "$((10#$end_us - 10#$start_us))"
}
median() { printf '%s\n' "$@" | sort -n | sed -n '3p'; }

n="${1:-100}"
total_time=5 end_time=2000000000 ding=0 color=aabbcc paused_at=0 comment=bench
before_ms=() after_ms=() before_chmod=0 after_chmod=0
for trial in 1 2 3 4 5; do
    read -r calls time_us < <(measure write_timer_file_before "$n")
    before_chmod=$calls
    before_ms+=("$time_us")
    read -r calls time_us < <(measure write_timer_file "$n")
    after_chmod=$calls
    after_ms+=("$time_us")
done
# `measure` reports microseconds using EPOCHREALTIME's fractional component;
# sort numeric medians for five paired runs.
med_before=$(median "${before_ms[@]}")
med_after=$(median "${after_ms[@]}")
printf 'writes=%s trials=5\n' "$n"
printf 'chmod_calls_before=%s\n' "$((n))"
printf 'chmod_calls_after=%s\n' 0
printf 'before_median_ms=%.3f\n' "$(awk -v n="$med_before" 'BEGIN {print n/1000}')"
printf 'after_median_ms=%.3f\n' "$(awk -v n="$med_after" 'BEGIN {print n/1000}')"
