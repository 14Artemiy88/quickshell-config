#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU/RAM single poll: FAIL: $*" >&2; exit 1; }

widget="$ROOT/components/CpuWidget.qml"
sampler="$ROOT/scripts/cpu_stats_once"
test -f "$widget" || fail "CpuWidget.qml missing"
test -x "$sampler" || test -f "$sampler" || fail "cpu_stats_once missing"
grep -Fq 'Quickshell.shellDir + "/scripts/cpu_stats_once"' "$widget" || fail "CPU/RAM sampler is not used"
grep -Fq 'Number(Config.cpuUpdateInterval || 1000) / 2' "$widget" || fail "sample window does not adapt to the configured CPU polling interval"
grep -Fq 'Math.max(50, Math.min(250,' "$widget" || fail "sample window isn't bounded to 50–250 ms"
grep -Fq 'root.ramValue = Math.max(0, Math.min(100, ram))' "$widget" || fail "RAM value is not consumed from sampler JSON"
if grep -Fq 'id: memProc' "$widget" || grep -Fq 'scripts/mem_stats_once' "$widget"; then
    fail "separate RAM process still exists in CpuWidget"
fi
[[ "$(grep -c '^[[:space:]]*Process {' "$widget")" -eq 1 ]] || fail "CpuWidget should own a single polling Process"
grep -Fq 'mem_usage_percent_into ram /proc/meminfo' "$sampler" || fail "sampler should use the shared RAM percentage helper without command substitution"
grep -Fq 'MemAvailable:' "$ROOT/scripts/cpu_stats.d/common.sh" || fail "shared RAM helper should use MemAvailable"
grep -Fq 'PROC_UPTIME="${CPU_STATS_PROC_UPTIME:-/proc/uptime}"' "$sampler" || fail "uptime must use the existing procfs sampling path"
grep -Fq 'read -r uptime_value _ < "$PROC_UPTIME"' "$sampler" || fail "uptime must be read without another process"

output="$(timeout 4s bash "$sampler")" || fail "cpu_stats_once failed"
python3 - "$output" <<'PY'
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception as exc:
    raise SystemExit(f"CPU/RAM single poll: invalid JSON: {exc}")
cpu = data.get("cpu")
ram = data.get("ram")
if not isinstance(cpu, list) or not cpu:
    raise SystemExit("CPU/RAM single poll: CPU values are missing")
if any(not isinstance(x, (int, float)) or x < 0 or x > 100 for x in cpu):
    raise SystemExit("CPU/RAM single poll: invalid core percentage")
if not isinstance(ram, (int, float)) or ram < 0 or ram > 100:
    raise SystemExit("CPU/RAM single poll: invalid RAM percentage")
used = data.get("ram_used_kib")
total = data.get("ram_total_kib")
if not isinstance(used, int) or not isinstance(total, int) or used < 0 or total < 0:
    raise SystemExit("CPU/RAM single poll: invalid RAM capacity fields")
if (total == 0 and used != 0) or (total > 0 and used > total):
    raise SystemExit("CPU/RAM single poll: inconsistent RAM capacity fields")
load_avg = data.get("load_avg")
if not isinstance(load_avg, list) or len(load_avg) not in (0, 3):
    raise SystemExit("CPU/RAM single poll: invalid load-average fields")
if load_avg and any(not isinstance(x, (int, float)) or x < 0 for x in load_avg):
    raise SystemExit("CPU/RAM single poll: invalid load-average values")
uptime_seconds = data.get("uptime_seconds")
if not isinstance(uptime_seconds, int) or uptime_seconds < -1:
    raise SystemExit("CPU/RAM single poll: invalid system uptime")
swap_used = data.get("swap_used_kib")
swap_total = data.get("swap_total_kib")
if not isinstance(swap_used, int) or not isinstance(swap_total, int) or swap_used < 0 or swap_total < 0:
    raise SystemExit("CPU/RAM single poll: invalid swap capacity fields")
if (swap_total == 0 and swap_used != 0) or (swap_total > 0 and swap_used > swap_total):
    raise SystemExit("CPU/RAM single poll: inconsistent swap capacity fields")
print(f"CPU/RAM single poll: OK ({len(cpu)} cores, RAM {ram}%, RAM {used}/{total} KiB, swap {swap_used}/{swap_total} KiB, load average {load_avg}, uptime {uptime_seconds}s)")
PY
