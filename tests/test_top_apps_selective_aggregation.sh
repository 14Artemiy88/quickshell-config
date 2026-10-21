#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps selective aggregation: FAIL: $*" >&2; exit 1; }
test_runtime_dir="$(mktemp -d)"
trap 'rm -rf "$test_runtime_dir" "$CALL_LOG"' EXIT
export XDG_RUNTIME_DIR="$test_runtime_dir"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

CALL_LOG="$(mktemp)"
export CALL_LOG

get_process_snapshot() {
    printf 'snapshot\n' >> "$CALL_LOG"
    printf 'appA\t50.0000\t4000\t100\t1\nappB\t25.0000\t2000\t200\t1\n'
}
aggregate_process_rows() {
    printf 'aggregate:%s\n' "$1" >> "$CALL_LOG"
    if [[ "$1" == cpu ]]; then
        printf 'appA\t50.0000\t1\t100\nappB\t25.0000\t1\t200\n'
    else
        printf 'appA\t4000\t1\t100\nappB\t2000\t1\t200\n'
    fi
}
get_cpu_capacity_percent() { printf 'capacity:cpu\n' >> "$CALL_LOG"; if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '800.0000'; else printf '800.0000\n'; fi; }
get_total_memory_kib() { printf 'capacity:ram\n' >> "$CALL_LOG"; if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '16000'; else printf '16000\n'; fi; }

# CPU-only should take one shared snapshot and skip the RAM ranking/capacity.
: > "$CALL_LOG"
cpu_output="$(get_top_apps 1 0)" || fail 'CPU-only request failed'
jq -e '.cpu | length == 2' <<< "$cpu_output" >/dev/null || fail "CPU-only request lost CPU rows: $cpu_output"
jq -e '.mem | length == 0' <<< "$cpu_output" >/dev/null || fail "CPU-only request returned RAM rows: $cpu_output"
[[ "$(grep -c '^snapshot$' "$CALL_LOG")" == 1 ]] || fail 'CPU-only request did not reuse one process snapshot'
grep -Fxq 'aggregate:cpu' "$CALL_LOG" || fail 'CPU-only request skipped CPU aggregation'
! grep -Fxq 'aggregate:mem' "$CALL_LOG" || fail 'CPU-only request ran RAM aggregation'
grep -Fxq 'capacity:cpu' "$CALL_LOG" || fail 'CPU-only request skipped CPU capacity'
! grep -Fxq 'capacity:ram' "$CALL_LOG" || fail 'CPU-only request computed RAM capacity'

# RAM-only likewise skips CPU aggregation and CPU normalization.
: > "$CALL_LOG"
ram_output="$(get_top_apps 0 1)" || fail 'RAM-only request failed'
jq -e '.cpu | length == 0' <<< "$ram_output" >/dev/null || fail "RAM-only request returned CPU rows: $ram_output"
jq -e '.mem | length == 2 and .[0].ratio == 0.25' <<< "$ram_output" >/dev/null || fail "RAM-only request lost RAM rows/ratio: $ram_output"
[[ "$(grep -c '^snapshot$' "$CALL_LOG")" == 1 ]] || fail 'RAM-only request did not reuse one process snapshot'
grep -Fxq 'aggregate:mem' "$CALL_LOG" || fail 'RAM-only request skipped RAM aggregation'
! grep -Fxq 'aggregate:cpu' "$CALL_LOG" || fail 'RAM-only request ran CPU aggregation'
grep -Fxq 'capacity:ram' "$CALL_LOG" || fail 'RAM-only request skipped RAM capacity'
! grep -Fxq 'capacity:cpu' "$CALL_LOG" || fail 'RAM-only request computed CPU capacity'

# Both sections still share a single snapshot and return both rankings.
: > "$CALL_LOG"
both_output="$(get_top_apps 1 1)" || fail 'combined request failed'
jq -e '.cpu | length == 2' <<< "$both_output" >/dev/null || fail 'combined request lost CPU rows'
jq -e '.mem | length == 2' <<< "$both_output" >/dev/null || fail 'combined request lost RAM rows'
[[ "$(grep -c '^snapshot$' "$CALL_LOG")" == 1 ]] || fail 'combined request sampled processes more than once'
[[ "$(grep -c '^aggregate:' "$CALL_LOG")" == 2 ]] || fail 'combined request did not run both aggregations exactly once'

# No requested section needs no process scan; no-arg calls remain backwards compatible.
: > "$CALL_LOG"
none_output="$(get_top_apps 0 0)" || fail 'empty request failed'
jq -e '.cpu | length == 0' <<< "$none_output" >/dev/null || fail 'empty request returned CPU rows'
jq -e '.mem | length == 0' <<< "$none_output" >/dev/null || fail 'empty request returned RAM rows'
[[ ! -s "$CALL_LOG" ]] || fail 'empty request performed unnecessary data collection'

: > "$CALL_LOG"
legacy_output="$(get_top_apps)" || fail 'legacy no-argument call failed'
jq -e '(.cpu | length == 2) and (.mem | length == 2)' <<< "$legacy_output" >/dev/null || fail 'legacy no-argument behavior no longer requests both sections'

# Wiring checks ensure the actual service forwards both independent toggles.
grep -Fq 'Settings.topAppsCpu ? "1" : "0"' "$ROOT/services/SystemMonitor.qml" || fail 'CPU toggle is not forwarded to monitor process'
grep -Fq 'Settings.topAppsRam ? "1" : "0"' "$ROOT/services/SystemMonitor.qml" || fail 'RAM toggle is not forwarded to monitor process'
grep -Fq 'get_top_apps "$WANT_TOP_APPS_CPU" "$WANT_TOP_APPS_RAM" "$WANT_TOP_APPS_SYSTEM_REMAINDER" "$TOP_APPS_SYSTEM_REMAINDER_LABEL"' "$ROOT/scripts/system_monitor" || fail 'monitor script does not forward split flags and remainder options'

echo 'Top Apps selective aggregation: OK'
