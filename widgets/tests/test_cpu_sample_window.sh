#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU adaptive sample window: FAIL: $*" >&2; exit 1; }
sampler="$ROOT/scripts/cpu_stats_once"
widget="$ROOT/components/CpuWidget.qml"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
cat > "$work/bin/sleep" <<'MOCK_SLEEP'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$CPU_SAMPLE_SLEEP_LOG"
MOCK_SLEEP
chmod +x "$work/bin/sleep"
cat > "$work/proc-stat" <<'STAT'
cpu 100 0 100 700 0 0 0 0 0 0
cpu0 100 0 100 700 0 0 0 0 0 0
STAT
export CPU_STATS_PROC_STAT="$work/proc-stat"
export CPU_SAMPLE_SLEEP_LOG="$work/sleep.log"
export PATH="$work/bin:$PATH"

for pair in '50 0.050' '100 0.100' '250 0.250'; do
    read -r ms expected <<< "$pair"
    : > "$CPU_SAMPLE_SLEEP_LOG"
    output="$(bash "$sampler" "$ms")" || fail "sampler failed for ${ms}ms"
    [[ "$(cat "$CPU_SAMPLE_SLEEP_LOG")" == "$expected" ]] || fail "${ms}ms request slept for $(cat "$CPU_SAMPLE_SLEEP_LOG"), expected $expected"
    python3 - "$output" <<'PY' || exit 1
import json, sys
x = json.loads(sys.argv[1])
assert isinstance(x.get("cpu"), list) and len(x["cpu"]) == 1
assert 0 <= x["cpu"][0] <= 100
assert isinstance(x.get("ram"), (int, float)) and 0 <= x["ram"] <= 100
PY
done

# The environment override remains available for callers that don't pass the
# new optional millisecond argument.
: > "$CPU_SAMPLE_SLEEP_LOG"
CPU_STATS_SAMPLE_INTERVAL=0.075 bash "$sampler" >/dev/null
[[ "$(cat "$CPU_SAMPLE_SLEEP_LOG")" == "0.075" ]] || fail "legacy environment-based sampling interval changed"

grep -Fq 'Number(Config.cpuUpdateInterval || 1000) / 2' "$widget" || fail "CpuWidget doesn't derive sample window from its configured interval"
grep -Fq 'Math.max(50, Math.min(250,' "$widget" || fail "CpuWidget sample window bounds are missing"
echo 'CPU adaptive sample window: OK'
