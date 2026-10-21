#!/usr/bin/env bash
set -euo pipefail

# Microbenchmark of the lock-file creation/acquisition fragments used by the
# three System Monitor collectors. The old path calls chmod for every lock;
# the new path sets umask before opening the descriptor. flock remains in both.
iterations="${1:-100}"
[[ "$iterations" =~ ^[0-9]+$ ]] && (( iterations > 0 )) || { echo "usage: $0 [positive-iterations]" >&2; exit 2; }
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

before_cycle() {
    local name
    for name in network-stat network-connections top-apps; do
        (
            exec 9>"$tmp/before-${name}.lock"
            chmod 600 "$tmp/before-${name}.lock" 2>/dev/null || true
            flock -x 9
            :
        )
    done
}

after_cycle() {
    local name
    for name in network-stat network-connections top-apps; do
        (
            umask 077
            exec 9>"$tmp/after-${name}.lock"
            flock -x 9
            :
        )
    done
}

measure() {
    local label="$1" i start end elapsed
    shift
    start="$(date +%s%N)"
    for ((i=0; i<iterations; i++)); do "$@"; done
    end="$(date +%s%N)"
    elapsed=$((end - start))
    printf '%s_ns=%s\n' "$label" "$elapsed"
}

for trial in 1 2 3 4 5; do
    measure "before_trial${trial}" before_cycle
    measure "after_trial${trial}" after_cycle
done
printf 'iterations=%s\n' "$iterations"
printf 'lock_acquisitions_per_side=%s\n' "$((iterations * 3))"
printf 'chmod_invocations_before=%s\n' "$((iterations * 3))"
printf 'chmod_invocations_after=0\n'
printf 'flock_invocations_per_side=%s\n' "$((iterations * 3))"
