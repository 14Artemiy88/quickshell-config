#!/usr/bin/env bash
# Compare the former sed+awk state-history parser against the Bash-only parser.
# Usage: benchmarks/bench_cpu_graph_state_parse_builtin.sh [state_reads=100] [trials=5]
set -euo pipefail
state_reads="${1:-100}"
trials="${2:-5}"
[[ "$state_reads" =~ ^[0-9]+$ && "$state_reads" -gt 0 ]] || { echo 'state_reads must be positive' >&2; exit 2; }
[[ "$trials" =~ ^[0-9]+$ && "$trials" -gt 0 ]] || { echo 'trials must be positive' >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
state="$work/graph-state"
history='0000'
for value in {1..50}; do history+=",$value"; done
printf 'v2 200 1000\n%s\n' "$history" > "$state"
old_ms=()
new_ms=()
for ((trial=1; trial<=trials; trial++)); do
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<state_reads; i++)); do
        IFS=' ' read -r state_version state_busy state_total < "$state" || true
        hist="$(sed -n '2p' "$state" 2>/dev/null || true)"
        [[ "$hist" =~ ^[0-9]+(,[0-9]+){50}$ ]] && \
            awk -F, '{ for (i=1; i<=NF; i++) if ($i < 0 || $i > 100) exit 1 }' <<< "$hist"
    done
    end="${EPOCHREALTIME/./}"
    old_ms+=("$(( (end-start) / 1000 ))")

    start="${EPOCHREALTIME/./}"
    for ((i=0; i<state_reads; i++)); do
        {
            IFS=' ' read -r state_version state_busy state_total || true
            IFS= read -r hist || true
        } < "$state"
        valid=1
        if [[ "$hist" =~ ^[0-9]+(,[0-9]+){50}$ ]]; then
            IFS=',' read -r -a values <<< "$hist"
            for value in "${values[@]}"; do
                value="${value#"${value%%[!0]*}"}"
                [[ -n "$value" ]] || value=0
                if [[ ! "$value" =~ ^[0-9]+$ ]] || (( ${#value} > 3 )) || \
                   { (( ${#value} == 3 )) && (( 10#$value > 100 )); }; then
                    valid=0
                    break
                fi
            done
        else
            valid=0
        fi
        (( valid )) || true
    done
    end="${EPOCHREALTIME/./}"
    new_ms+=("$(( (end-start) / 1000 ))")
done
sort_numbers() { printf '%s\n' "$@" | sort -n; }
median() { local -a sorted; mapfile -t sorted < <(sort_numbers "$@"); printf '%s' "${sorted[$((${#sorted[@]}/2))]}"; }
printf 'CPU graph state parser comparison (%d state loads; median of %d trials)\n' "$state_reads" "$trials"
printf 'Before: 2 external processes per state load (sed + awk), %s ms median\n' "$(median "${old_ms[@]}")"
printf 'After:  0 external processes per state load, %s ms median\n' "$(median "${new_ms[@]}")"
