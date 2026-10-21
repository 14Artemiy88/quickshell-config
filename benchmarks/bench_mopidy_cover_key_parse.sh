#!/usr/bin/env bash
# Compact reproducible microbenchmark for the per-poll Mopidy cover-cache key.
set -euo pipefail
TRACK_URI='http://music.test/track id?source=library'
ITERATIONS="${1:-150}"
TRIALS="${2:-5}"

measure() {
    local mode="$1" trial="$2" start end key hash_output i
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<ITERATIONS; i++)); do
        if [[ "$mode" == before ]]; then
            key="$(printf '%s' "$TRACK_URI" | sha256sum | awk '{print $1}')"
        else
            hash_output="$(printf '%s' "$TRACK_URI" | sha256sum)"
            key="${hash_output%% *}"
        fi
        [[ "$key" =~ ^[0-9a-f]{64}$ ]] || return 1
    done
    end="${EPOCHREALTIME/./}"
    printf '%s\n' "$((end - start))"
}

before_values=()
after_values=()
for ((trial=1; trial<=TRIALS; trial++)); do
    before_values+=("$(measure before "$trial")")
    after_values+=("$(measure after "$trial")")
done
before_median="$(printf '%s\n' "${before_values[@]}" | sort -n | sed -n "$(((TRIALS + 1) / 2))p")"
after_median="$(printf '%s\n' "${after_values[@]}" | sort -n | sed -n "$(((TRIALS + 1) / 2))p")"
printf 'iterations per trial: %s; trials: %s\n' "$ITERATIONS" "$TRIALS"
printf 'before: median %s ms; awk calls %s\n' "$((before_median / 1000))" "$((ITERATIONS * TRIALS))"
printf 'after:  median %s ms; awk calls 0\n' "$((after_median / 1000))"
