#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU/RAM single poll: FAIL: $*" >&2; exit 1; }

widget="$ROOT/components/CpuWidget.qml"
sampler="$ROOT/scripts/cpu_stats_once"
test -f "$widget" || fail "CpuWidget.qml missing"
test -x "$sampler" || test -f "$sampler" || fail "cpu_stats_once missing"
grep -Fq 'command: ["bash", Quickshell.shellDir + "/scripts/cpu_stats_once"]' "$widget" || fail "CPU/RAM sampler is not used"
grep -Fq 'root.ramValue = Math.max(0, Math.min(100, ram))' "$widget" || fail "RAM value is not consumed from sampler JSON"
if grep -Fq 'id: memProc' "$widget" || grep -Fq 'scripts/mem_stats_once' "$widget"; then
    fail "separate RAM process still exists in CpuWidget"
fi
[[ "$(grep -c '^[[:space:]]*Process {' "$widget")" -eq 1 ]] || fail "CpuWidget should own a single polling Process"
grep -Fq 'MemAvailable:' "$sampler" || fail "sampler should use MemAvailable for RAM percentage"

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
print(f"CPU/RAM single poll: OK ({len(cpu)} cores, RAM {ram}%)")
PY
