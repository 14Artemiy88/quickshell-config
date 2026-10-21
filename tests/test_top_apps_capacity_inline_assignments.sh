#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
fail() { echo "Top Apps capacity inline assignment: FAIL: $*" >&2; exit 1; }
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/cpu-online" <<'CPU'
0-3,8,10-13
CPU
cat > "$tmp/meminfo" <<'MEM'
MemFree: 100 kB
MemTotal: 32768000 kB
MEM
export TOP_APPS_CPU_ONLINE="$tmp/cpu-online" TOP_APPS_MEMINFO="$tmp/meminfo"

expected="$(get_cpu_capacity_percent)"
actual='unset'
get_cpu_capacity_percent actual || fail 'direct CPU capacity assignment failed'
[[ "$actual" == "$expected" && "$actual" == '900.0000' ]] || fail "CPU capacity API mismatch: stdout=[$expected] direct=[$actual]"

expected="$(get_total_memory_kib)"
actual='unset'
get_total_memory_kib actual || fail 'direct memory capacity assignment failed'
[[ "$actual" == "$expected" && "$actual" == '32768000' ]] || fail "memory capacity API mismatch: stdout=[$expected] direct=[$actual]"

# Missing MemTotal must clear the destination to zero, not leave stale content.
printf 'MemFree: 12 kB\n' > "$tmp/meminfo-empty"
TOP_APPS_MEMINFO="$tmp/meminfo-empty"
actual='stale-value'
get_total_memory_kib actual || fail 'missing MemTotal parser failed'
[[ "$actual" == '0' ]] || fail "missing MemTotal left unexpected output [$actual]"

body="$(sed -n '/^get_top_apps() {/,/^}/p' "$ROOT/scripts/system_monitor.d/top_apps.sh")"
grep -Fq 'get_cpu_capacity_percent cpu_capacity' <<< "$body" || fail 'Top Apps CPU path does not use direct capacity assignment'
grep -Fq 'get_total_memory_kib total_memory_kib' <<< "$body" || fail 'Top Apps RAM path does not use direct memory assignment'
! grep -Fq 'cpu_capacity="$(get_cpu_capacity_percent)' <<< "$body" || fail 'Top Apps CPU path still uses command substitution'
! grep -Fq 'total_memory_kib="$(get_total_memory_kib)' <<< "$body" || fail 'Top Apps RAM path still uses command substitution'

echo 'Top Apps capacity inline assignment: OK'
