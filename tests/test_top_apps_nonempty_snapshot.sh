#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps non-empty snapshot: FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || fail 'jq is required'
command -v yes >/dev/null 2>&1 || fail 'yes is required to create deterministic CPU load'
workdir="$(mktemp -d)"
export XDG_RUNTIME_DIR="$workdir/runtime"
mkdir -p "$XDG_RUNTIME_DIR"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
yes >/dev/null & burner_pid=$!
cleanup() {
    kill "$burner_pid" 2>/dev/null || true
    wait "$burner_pid" 2>/dev/null || true
    rm -rf "$workdir"
}
trap cleanup EXIT

# First snapshot establishes the CPU baseline; RAM should already have entries.
first="$(get_top_apps 1 1)" || fail 'first snapshot failed'
jq -e '.mem | length > 0' <<< "$first" >/dev/null || fail "RAM list unexpectedly empty: $first"

# Let the burner accrue CPU ticks, then sample again. This catches cases where
# a collector silently drops all /proc process rows and leaves both panels empty.
sleep 0.3
second="$(get_top_apps 1 1)" || fail 'second snapshot failed'
jq -e '.mem | length > 0' <<< "$second" >/dev/null || fail "RAM list unexpectedly empty after second sample: $second"
jq -e '.cpu | length > 0' <<< "$second" >/dev/null || fail "CPU list unexpectedly empty under active CPU load: $second"
jq -e '.cpu | any(.[]; .name == "yes")' <<< "$second" >/dev/null || fail "CPU load process is missing from CPU list: $second"

# Verify the same non-empty arrays survive the actual System Monitor JSON path.
sleep 0.1
monitor_output="$("$ROOT/scripts/system_monitor" 1 0 0 0 1 1)" || fail 'system_monitor invocation failed'
jq -e '.top_apps.mem | length > 0' <<< "$monitor_output" >/dev/null || fail "System Monitor emitted an empty RAM list: $monitor_output"
jq -e '.top_apps.cpu | length > 0' <<< "$monitor_output" >/dev/null || fail "System Monitor emitted an empty CPU list under load: $monitor_output"
state_file="$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${UID}.tsv"
awk -F '\t' '$1 == "S" && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ { found=1 } END { if (!found) exit 1 }' "$state_file" || fail "CPU state does not retain the aggregate /proc/stat baseline"
awk -F '\t' '$1 == "L" { if ($2 !~ /^[0-9]+([.][0-9]+)?$/ || $2 < 0 || $2 > 100) exit 1; found=1 } END { if (!found) exit 1 }' "$state_file" || fail "CPU state does not contain a valid aggregate utilization percentage"

echo 'Top Apps non-empty snapshot: OK'
