#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIMITIVE="$ROOT/components/primitives/SegmentBarGraph.qml"
CPU_GRAPH="$ROOT/components/CpuGraph.qml"
FLOW_PRIMITIVE="$ROOT/components/primitives/FlowingSegmentBarGraph.qml"
CAVA="$ROOT/components/Cava.qml"
for file in "$PRIMITIVE" "$FLOW_PRIMITIVE" "$CPU_GRAPH" "$CAVA"; do test -f "$file"; done

grep -Fq 'property var valuesModel: null' "$PRIMITIVE"
grep -Fq 'property int barCount:' "$PRIMITIVE"
grep -Fq 'property real slotWidth: 0' "$PRIMITIVE"
grep -Fq 'property real barWidthRatio: 0' "$PRIMITIVE"
grep -Fq 'property string direction: "up"' "$PRIMITIVE"
grep -Fq 'Math.max(1, Math.min(availableHeight, percent * availableHeight / 100))' "$PRIMITIVE"
grep -Fq 'Config.cpuGraphMode === "both"' "$CPU_GRAPH"
grep -Fq 'Config.cpuGraphMode === "top"' "$CPU_GRAPH"
grep -Fq 'Config.cpuGraphMode === "bottom"' "$CPU_GRAPH"
grep -Fq 'Config.cavaMode === "both"' "$CAVA"
grep -Fq 'Config.cavaMode === "top"' "$CAVA"
grep -Fq 'Config.cavaMode === "bottom"' "$CAVA"

python3 - "$PRIMITIVE" "$FLOW_PRIMITIVE" "$CPU_GRAPH" "$CAVA" <<'PYCODE'
from pathlib import Path
import re, sys
pairs={')':'(',']':'[','}':'{'}
def check_balance(name):
    source=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1 < len(source) else ''
        if line_comment:
            if c=='\n': line_comment=False
            i+=1; continue
        if block_comment:
            if c=='*' and n=='/': block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line_comment=True; i+=2; continue
        if c=='/' and n=='*': block_comment=True; i+=2; continue
        if c in ('"', "'", '`'): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0] != pairs[c]:
                raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
for name in sys.argv[1:]: check_balance(name)
primitive, flow_primitive, cpu, cava = [Path(name).read_text(encoding='utf-8') for name in sys.argv[1:]]
if cpu.count('Primitives.FlowingSegmentBarGraph {') != 4:
    raise SystemExit('CpuGraph must use the flowing segment graph in all four display regions')
if cava.count('Primitives.SegmentBarGraph {') != 4:
    raise SystemExit('Cava must use the shared segment graph in all four display regions')
for source, label in ((cpu,'CpuGraph'),(cava,'Cava')):
    if re.search(r'(?m)^\s*(?:Repeater|Rectangle) \{', source):
        raise SystemExit(f'{label} still duplicates the bar repeater/rectangle renderer')
for source, label in ((primitive,'SegmentBarGraph'),(flow_primitive,'FlowingSegmentBarGraph')):
    if source.count('Repeater {') != 1 or source.count('Rectangle {') != 1:
        raise SystemExit(f'{label} must own exactly one repeater and one rectangle renderer')
if 'model: root.valuesModel' not in primitive or 'required property real value' not in primitive or 'root.barHeightFor(value, parent.height)' not in primitive or 'root.spacing' not in primitive:
    raise SystemExit('SegmentBarGraph is missing role-based model/spacing binding')
if 'valuesModel: cavaValuesModel' not in cava or cava.count('valuesModel: cavaValuesModel') != 4:
    raise SystemExit('CAVA regions must share one incremental value model')
if 'CpuGraphData.buildFlowFrame' not in flow_primitive or 'Easing.Linear' not in flow_primitive:
    raise SystemExit('FlowingSegmentBarGraph is missing continuous sample flow')
print('CPU graph uses flowing renderer; CAVA uses shared incremental segment-bar model: OK')
PYCODE

echo 'Segment bar graph primitive test: OK'
