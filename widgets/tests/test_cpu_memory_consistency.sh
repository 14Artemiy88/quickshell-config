#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU/RAM memory consistency: FAIL: $*" >&2; exit 1; }
helper="$ROOT/scripts/cpu_stats.d/common.sh"
source "$helper"
fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT

cat > "$fixture" <<'MEMINFO'
MemTotal:       16000000 kB
MemFree:         4000000 kB
MemAvailable:   12000000 kB
Buffers:          100000 kB
Cached:          3000000 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "25" ]] || fail "expected 25% used when MemAvailable is 75% of MemTotal"

cat > "$fixture" <<'MEMINFO'
MemTotal:       1000 kB
MemAvailable:   1200 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "0" ]] || fail "available memory above total should clamp usage to 0%"

cat > "$fixture" <<'MEMINFO'
MemTotal:       1000 kB
MemAvailable:   0 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "100" ]] || fail "zero available memory should report 100% used"

cat > "$fixture" <<'MEMINFO'
MemTotal:       200 kB
MemAvailable:   149 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "26" ]] || fail "percentage should round to nearest whole number"

cat > "$fixture" <<'MEMINFO'
MemAvailable:   10 kB
MemFree:        5 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "0" ]] || fail "missing MemTotal should report 0%"

cat > "$fixture" <<'MEMINFO'
MemTotal:       invalid kB
MemAvailable:   10 kB
MEMINFO
[[ "$(mem_usage_percent "$fixture")" == "0" ]] || fail "invalid MemTotal should report 0%"

for script in cpu_stats cpu_stats_once mem_stats_once; do
    path="$ROOT/scripts/$script"
    grep -Fq 'mem_usage_percent /proc/meminfo' "$path" || fail "$script doesn't use the shared memory helper"
done
if grep -Fq 'free | awk' "$ROOT/scripts/cpu_stats" "$ROOT/scripts/cpu_stats_once" "$ROOT/scripts/mem_stats_once"; then
    fail "a collector still uses the free-based memory formula"
fi
grep -Fq 'MemAvailable:' "$helper" || fail "shared helper no longer uses MemAvailable"

echo "CPU/RAM memory consistency: OK"
