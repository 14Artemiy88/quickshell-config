#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIMITIVE="$ROOT/components/primitives/ProgressTrack.qml"
METRIC="$ROOT/components/MetricBar.qml"
TOP_APPS="$ROOT/components/TopApps.qml"
VOLUMES="$ROOT/components/Volumes.qml"
for f in "$PRIMITIVE" "$METRIC" "$TOP_APPS" "$VOLUMES"; do
    test -f "$f" || { echo "ProgressTrack primitive: missing $f" >&2; exit 1; }
done

grep -Fq 'property real value: 0' "$PRIMITIVE"
grep -Fq 'property color fillColor:' "$PRIMITIVE"
grep -Fq 'property color trackColor:' "$PRIMITIVE"
grep -Fq 'property string direction: "leftToRight"' "$PRIMITIVE"
grep -Fq 'Math.max(0, Math.min(100, v))' "$PRIMITIVE"
grep -Fq 'root.direction === "rightToLeft"' "$PRIMITIVE"
grep -Fq 'root.direction === "bottomToTop"' "$PRIMITIVE"
grep -Fq 'Primitives.ProgressTrack {' "$METRIC"
grep -Fq 'Primitives.ProgressTrack {' "$TOP_APPS"
grep -Fq 'Primitives.ProgressTrack {' "$VOLUMES"

python3 - "$PRIMITIVE" "$METRIC" "$TOP_APPS" "$VOLUMES" <<'PYCODE'
from pathlib import Path
import sys
primitive, metric, top_apps, volumes = [Path(p).read_text(encoding='utf-8') for p in sys.argv[1:]]
if metric.count('Primitives.ProgressTrack {') != 2:
    raise SystemExit('MetricBar must use shared track for horizontal and vertical gauges')
if top_apps.count('Primitives.ProgressTrack {') != 1:
    raise SystemExit('TopApps must use shared track for relative-use bars')
if primitive.count('Rectangle {') != 2:
    raise SystemExit('ProgressTrack must own one track and one fill rectangle')
if 'id: horizontalTrack' in metric:
    raise SystemExit('MetricBar still contains the previous horizontal track renderer')
if 'id: verticalTrack' in metric:
    raise SystemExit('MetricBar still contains the previous vertical track renderer')
if 'width: parent.width * appRow.relativeUsage' in top_apps:
    raise SystemExit('TopApps still contains its duplicate fill renderer')
if volumes.count('Primitives.ProgressTrack {') != 2:
    raise SystemExit('Volumes must use ProgressTrack for main and per-stream volume bars')
if 'Rectangle {' in volumes:
    raise SystemExit('Volumes still contains a duplicate Rectangle track/fill renderer')
if volumes.count('MouseArea {') != 2:
    raise SystemExit('Volumes must retain drag/wheel MouseAreas for main and per-stream controls')
for snippet in ('root.applyMainVolume(root.mainDragValue, true)', 'root.applyStreamVolume(modelData.num, streamColumn.dragValue)', 'onWheel: wheel =>'):
    if snippet not in volumes:
        raise SystemExit(f'Volumes lost interaction handler: {snippet}')
print('ProgressTrack primitive: shared renderer wiring OK, including volume controls')
PYCODE

echo 'ProgressTrack primitive test: OK'
