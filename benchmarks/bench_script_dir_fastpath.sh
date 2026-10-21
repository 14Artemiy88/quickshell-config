#!/usr/bin/env bash
# Compare the previous dirname+cd+pwd setup with Bash path parameter expansion.
# Usage: benchmarks/bench_script_dir_fastpath.sh [iterations=500] [trials=5]
set -euo pipefail
iterations="${1:-500}"
trials="${2:-5}"
[[ "$iterations" =~ ^[0-9]+$ && "$iterations" -gt 0 ]] || { echo 'iterations must be a positive integer' >&2; exit 2; }
[[ "$trials" =~ ^[0-9]+$ && "$trials" -gt 0 ]] || { echo 'trials must be a positive integer' >&2; exit 2; }
script_path="${BASH_SOURCE[0]}"
# Use a representative project-relative path containing nested directories.
sample_path='scripts/system_monitor.d/top_apps.sh'
printf 'method,trial,iterations,elapsed_us,external_dirname_processes\n'
for ((trial=1; trial<=trials; trial++)); do
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<iterations; i++)); do
        resolved="$(cd -- "$(dirname -- "$sample_path")" && pwd)"
    done
    end="${EPOCHREALTIME/./}"
    printf 'before_dirname,%d,%d,%d,%d\n' "$trial" "$iterations" "$((end-start))" "$iterations"

    start="${EPOCHREALTIME/./}"
    for ((i=0; i<iterations; i++)); do
        resolved="${sample_path%/*}"
        [[ "$resolved" != "$sample_path" ]] || resolved='.'
    done
    end="${EPOCHREALTIME/./}"
    printf 'after_bash_parameter_expansion,%d,%d,%d,0\n' "$trial" "$iterations" "$((end-start))"
done
