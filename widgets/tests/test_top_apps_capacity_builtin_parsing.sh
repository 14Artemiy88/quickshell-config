#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
fail() { echo "Top Apps capacity built-in parsing: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/meminfo" <<'MEM'
MemTotal:       32768000 kB
MemFree:        10000000 kB
MEM
TOP_APPS_MEMINFO="$tmp/meminfo"
export TOP_APPS_MEMINFO
[[ "$(get_total_memory_kib)" == 32768000 ]] || fail "MemTotal should be parsed without AWK"

: > "$tmp/cpuinfo"
for i in 0 1 2 3 4 5 6 7; do printf 'processor : %s\n' "$i" >> "$tmp/cpuinfo"; done
TOP_APPS_CPUINFO="$tmp/cpuinfo"
export TOP_APPS_CPUINFO
# CPU online ranges should be counted with Bash built-ins, without getconf.
mkdir "$tmp/bin"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/getconf"
chmod +x "$tmp/bin/getconf"
PATH="$tmp/bin:$PATH"
export PATH
printf '0-3,8,10-13\n' > "$tmp/cpu-online"
TOP_APPS_CPU_ONLINE="$tmp/cpu-online"
export TOP_APPS_CPU_ONLINE
[[ "$(get_cpu_capacity_percent)" == 900.0000 ]] || fail "online CPU ranges should count nine logical CPUs"

# Force fallback when sysfs is unavailable; getconf failure should fall back to cpuinfo.
TOP_APPS_CPU_ONLINE="$tmp/missing-cpu-online"
export TOP_APPS_CPU_ONLINE
[[ "$(get_cpu_capacity_percent)" == 800.0000 ]] || fail "cpuinfo fallback should count eight logical CPUs"

cat > "$tmp/meminfo-empty" <<'MEM'
MemFree: 12 kB
MEM
TOP_APPS_MEMINFO="$tmp/meminfo-empty"
export TOP_APPS_MEMINFO
[[ "$(get_total_memory_kib)" == 0 ]] || fail "missing MemTotal should return zero"

echo "Top Apps capacity built-in parsing: OK"
