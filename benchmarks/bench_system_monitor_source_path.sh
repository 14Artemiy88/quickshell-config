#!/usr/bin/env bash
# Compare the six former dirname invocations with one built-in SCRIPT_DIR setup.
# Usage: benchmarks/bench_system_monitor_source_path.sh [launches=100] [trials=5]
set -euo pipefail
launches="${1:-100}"
trials="${2:-5}"
[[ "$launches" =~ ^[0-9]+$ && "$launches" -gt 0 ]] || { echo 'launches must be a positive integer' >&2; exit 2; }
[[ "$trials" =~ ^[0-9]+$ && "$trials" -gt 0 ]] || { echo 'trials must be a positive integer' >&2; exit 2; }
sample_path='scripts/system_monitor'
source_count=6
printf 'method,trial,simulated_launches,source_path_resolutions,elapsed_us,external_dirname_processes\n'
for ((trial=1; trial<=trials; trial++)); do
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<launches; i++)); do
        for ((source=0; source<source_count; source++)); do
            resolved="$(dirname -- "$sample_path")"
        done
    done
    end="${EPOCHREALTIME/./}"
    printf 'before_repeated_dirname,%d,%d,%d,%d,%d\n' \
        "$trial" "$launches" "$((launches * source_count))" "$((end-start))" "$((launches * source_count))"

    start="${EPOCHREALTIME/./}"
    for ((i=0; i<launches; i++)); do
        SCRIPT_PATH="$sample_path"
        SCRIPT_DIR="${SCRIPT_PATH%/*}"
        [[ "$SCRIPT_DIR" != "$SCRIPT_PATH" ]] || SCRIPT_DIR=.
        resolved="$SCRIPT_DIR"
    done
    end="${EPOCHREALTIME/./}"
    printf 'after_single_bash_resolution,%d,%d,%d,%d,0\n' \
        "$trial" "$launches" "$launches" "$((end-start))"
done
