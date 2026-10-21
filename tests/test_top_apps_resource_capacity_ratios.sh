#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps total-resource ratios: FAIL: $*" >&2; exit 1; }
source_script="$ROOT/scripts/system_monitor.d/top_apps.sh"
[[ -f "$source_script" ]] || fail "top_apps.sh is missing"
test_runtime_dir="$(mktemp -d)"
trap 'rm -rf "$test_runtime_dir"' EXIT
export XDG_RUNTIME_DIR="$test_runtime_dir"
source "$source_script"

# Deterministic ratio math: bars are fractions of total system capacity.
[[ "$(calculate_resource_ratio 250 800)" == "0.3125" ]] || fail "CPU ratio should be 250/800, not relative to the top app"
[[ "$(calculate_resource_ratio 4000 16000)" == "0.2500" ]] || fail "RAM ratio should be 4000/16000"
[[ "$(calculate_resource_ratio 10 0)" == "0.0000" ]] || fail "zero/unknown capacity should result in an empty bar"
[[ "$(calculate_resource_ratio 20 10)" == "1.0000" ]] || fail "ratios above capacity should clamp to 1"
[[ "$(calculate_resource_ratio -1 100)" == "0.0000" ]] || fail "negative values should result in an empty bar"

# Use a fixed process fixture and fixed system capacities to ensure the top row
# is not automatically 100%: 50 CPU percentage points out of 800 capacity is 6.25%,
# while 4000 KiB out of 16000 KiB total RAM is 25%.
get_process_snapshot() {
    printf 'appA\t50.0000\t4000\t100\t1\nappB\t25.0000\t2000\t200\t1\nappC\t10.0000\t1000\t300\t1\n'
}
get_cpu_capacity_percent() { if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '800.0000'; else printf '800.0000\n'; fi; }
get_total_memory_kib() { if [[ -n "${1:-}" ]]; then printf -v "$1" '%s' '16000'; else printf '16000\n'; fi; }
output="$(get_top_apps)" || fail "get_top_apps failed with fixed fixture"
printf '%s\n' "$output" | jq -e '
  .cpu[0].name == "appA" and .cpu[0].ratio == 0.0625 and .cpu[0].value == "6.2%" and
  .mem[0].name == "appA" and .mem[0].ratio == 0.25 and
  .cpu[1].ratio == 0.0312 and .mem[1].ratio == 0.125
' >/dev/null || fail "producer ratios do not use total system capacities: $output"

echo "Top Apps total-resource ratios: OK"
