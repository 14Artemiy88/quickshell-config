#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home" XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/share" XDG_STATE_HOME="$HOME/state" XDG_CACHE_HOME="$HOME/cache" XDG_RUNTIME_DIR="$WORK/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/env"
source "$ROOT/scripts/timer.d/common.sh"
noop_callback() { :; }
timer_ensure_dirs

old_timer_with_lock() {
    local callback="$1" lock_fd status
    shift
    timer_ensure_dirs || return 1
    command -v flock >/dev/null 2>&1 || return 1
    exec {lock_fd}>"$TIMER_DIR/.state.lock" || return 1
    flock -x "$lock_fd" || { exec {lock_fd}>&-; return 1; }
    "$callback" "$@"
    status=$?
    flock -u "$lock_fd" 2>/dev/null || true
    exec {lock_fd}>&-
    return "$status"
}

measure() {
    local fn="$1" count="$2" i start end
    start=$(date +%s%N)
    for ((i=0; i<count; i++)); do "$fn" noop_callback; done
    end=$(date +%s%N)
    printf '%s\n' "$((end - start))"
}

trials=5
count="${1:-100}"
old_values=()
new_values=()
for ((trial=0; trial<trials; trial++)); do
    old_values+=("$(measure old_timer_with_lock "$count")")
    new_values+=("$(measure timer_with_lock "$count")")
done
median() {
    printf '%s\n' "$@" | sort -n | sed -n '3p'
}
old_ns=$(median "${old_values[@]}")
new_ns=$(median "${new_values[@]}")
printf 'transactions=%s trials=%s\n' "$count" "$trials"
printf 'before_median_ms=%.3f\n' "$(awk -v n="$old_ns" 'BEGIN {print n/1000000}')"
printf 'after_median_ms=%.3f\n' "$(awk -v n="$new_ns" 'BEGIN {print n/1000000}')"
printf 'external_flock_calls_before=%s\n' "$((count * 2))"
printf 'external_flock_calls_after=%s\n' "$count"
