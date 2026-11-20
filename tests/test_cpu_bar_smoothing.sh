#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACK="$ROOT/components/primitives/ProgressTrack.qml"
METRIC="$ROOT/components/MetricBar.qml"
CPU="$ROOT/components/CpuWidget.qml"
CHECK="$ROOT/CHECK.sh"
for f in "$TRACK" "$METRIC" "$CPU"; do test -f "$f"; done

grep -Fq 'property int valueAnimationDuration: 0' "$TRACK"
grep -Fq 'property real displayedValue: value' "$TRACK"
grep -Fq 'Behavior on displayedValue' "$TRACK"
grep -Fq 'enabled: root.valueAnimationDuration > 0' "$TRACK"
grep -Fq 'valueAnimationDuration: root.valueAnimationDuration' "$METRIC"
grep -Fq 'valueAnimationDuration: index === 8 ? 0 : root.cpuBarAnimationDuration' "$CPU"
grep -Fq 'Config.animationDurationForProfile(' "$CPU"
grep -Fq 'Config.animationCpuMorphProfile,' "$CPU"
grep -Fq 'Math.min(cpuBarAdaptiveDuration, Number(Config.animationCpuMorphDuration) || 0)' "$CPU"
grep -Fq 'cpuBarAdaptiveDuration: Math.max(' "$CPU"
grep -Fq 'valueAnimationProfile: Config.animationCpuMorphProfile' "$CPU"
grep -Fq 'test_cpu_bar_smoothing.sh' "$CHECK"

python3 - "$TRACK" "$METRIC" "$CPU" <<'PYCODE'
from pathlib import Path
import sys
track, metric, cpu = [Path(p).read_text(encoding='utf-8') for p in sys.argv[1:]]
if track.count('Behavior on displayedValue') != 1:
    raise SystemExit('ProgressTrack must have one opt-in value behavior')
if metric.count('valueAnimationDuration: root.valueAnimationDuration') != 2:
    raise SystemExit('MetricBar must forward optional smoothing to horizontal and vertical gauges')
if metric.count('valueAnimationProfile: root.valueAnimationProfile') != 2:
    raise SystemExit('MetricBar must forward the selected easing profile to both orientations')
if 'valueAnimationDuration: index === 8 ? 0 : root.cpuBarAnimationDuration' not in cpu:
    raise SystemExit('RAM must remain immediate while CPU cores use the configured animation')
if cpu.count('valueAnimationDuration: index === 8 ? 0 : root.cpuBarAnimationDuration') != 2:
    raise SystemExit('CPU smoothing must apply in both orientations, but not to the RAM gauge')
print('CPU-only configurable, sample-adaptive smoothing; RAM and ProgressTrack consumers without a duration remain immediate: OK')
PYCODE

echo 'CPU bar smoothing test: OK'
