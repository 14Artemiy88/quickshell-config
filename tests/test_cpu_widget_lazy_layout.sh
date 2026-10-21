#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU/RAM lazy layout: FAIL: $*" >&2; exit 1; }
widget="$ROOT/components/CpuWidget.qml"
test -f "$widget" || fail "CpuWidget.qml missing"

# Hidden Qt Quick positioners still construct Repeater delegates. A single
# Loader must own the active orientation so inactive MetricBars are not built.
grep -Fq 'Loader {' "$widget" || fail "layout Loader missing"
grep -Fq 'sourceComponent: (Config.cpuBarDirection === "topToBottom" || Config.cpuBarDirection === "bottomToTop")' "$widget" || fail "Loader does not select the vertical layout"
grep -Fq '? verticalLayoutComponent' "$widget" || fail "vertical component not selected"
grep -Fq ': horizontalLayoutComponent' "$widget" || fail "horizontal component not selected"
[[ "$(grep -c '^[[:space:]]*Component {' "$widget")" -eq 2 ]] || fail "expected exactly two layout components"
[[ "$(grep -c '^[[:space:]]*Repeater {' "$widget")" -eq 2 ]] || fail "each orientation must own exactly one Repeater"
grep -Fq 'id: horizontalLayoutComponent' "$widget" || fail "horizontal component missing"
grep -Fq 'id: verticalLayoutComponent' "$widget" || fail "vertical component missing"
[[ "$(grep -c 'model: Config.cpuShowRam ? 9 : 8' "$widget")" -eq 2 ]] || fail "CPU/RAM delegate count must be 8 cores or 9 meters with RAM for both directions"
[[ "$(grep -c 'index === 8 ? root.ramValue' "$widget")" -eq 2 ]] || fail "RAM delegate not routed through the 9th meter"
if grep -Eq '^[[:space:]]*visible: Config\.cpuBarDirection' "$widget"; then
    fail "old simultaneously-created direction layouts remain"
fi
if grep -Fq 'visible: Config.cpuShowRam' "$widget"; then
    fail "hidden horizontal RAM MetricBar is still always instantiated"
fi
[[ "$(grep -c '^[[:space:]]*Process {' "$widget")" -eq 1 ]] || fail "CPU/RAM sampler process count changed"
grep -Fq 'if (!cpuProc.running)' "$widget" || fail "poll overlap guard missing"
echo "CPU/RAM lazy layout: OK (17–18 potential meters reduced to 8–9 active meters; process count unchanged)"
