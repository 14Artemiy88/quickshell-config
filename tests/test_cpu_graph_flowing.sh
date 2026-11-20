#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CPU_GRAPH="$ROOT/components/CpuGraph.qml"
FLOW_GRAPH="$ROOT/components/primitives/FlowingSegmentBarGraph.qml"
HELPER="$ROOT/js/cpuGraphData.js"
CHECK="$ROOT/CHECK.sh"
for file in "$CPU_GRAPH" "$FLOW_GRAPH" "$HELPER"; do test -f "$file"; done

[[ "$(grep -c 'Primitives.FlowingSegmentBarGraph {' "$CPU_GRAPH")" -eq 4 ]] || { echo 'CPU graph must use the flowing renderer in all four regions' >&2; exit 1; }
grep -Fq 'property int flowDuration: 992' "$FLOW_GRAPH"
grep -Fq 'property real smoothedSampleInterval: 1000' "$FLOW_GRAPH"
grep -Fq 'ListModel {' "$FLOW_GRAPH"
grep -Fq 'model: flowModel' "$FLOW_GRAPH"
grep -Fq 'function syncFlowModel(values)' "$FLOW_GRAPH"
grep -Fq 'function rotateFlowModel(values)' "$FLOW_GRAPH"
grep -Fq 'flowModel.move(1, 0, values.length)' "$FLOW_GRAPH"
grep -Fq 'root.rotateFlowModel(settled)' "$FLOW_GRAPH"
grep -Fq 'flowModel.setProperty(frame.length - 1' "$FLOW_GRAPH"
if grep -Fq 'model: root.isFlowing ? root.flowFrame : root.displayedValues' "$FLOW_GRAPH"; then echo 'flow graph must not replace the Repeater model at every sample' >&2; exit 1; fi
grep -Fq 'var sampleAt = Date.now()' "$FLOW_GRAPH"
grep -Fq 'CpuGraphData.smoothSampleInterval(' "$FLOW_GRAPH"
grep -Fq 'CpuGraphData.resolveFlowDuration(root.smoothedSampleInterval)' "$FLOW_GRAPH"
grep -Fq 'root.pendingFlowDuration = nextFlowDuration' "$FLOW_GRAPH"
grep -Fq 'root.beginFlow(pending, pendingDuration)' "$FLOW_GRAPH"
grep -Fq 'easing.type: Easing.Linear' "$FLOW_GRAPH"
grep -Fq 'to: -root.slotPitch' "$FLOW_GRAPH"
grep -Fq 'root.flowFrame = frame' "$FLOW_GRAPH"
grep -Fq 'root.displayedValues = settled' "$FLOW_GRAPH"
grep -Fq 'root.pendingValues = next' "$FLOW_GRAPH"
grep -Fq 'test_cpu_graph_flowing.sh' "$CHECK"

node - "$HELPER" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const context = {};
vm.runInNewContext(source, context, {filename: 'cpuGraphData.js'});
const previous = [10, 20, 30, 40];
const next = [20, 30, 40, 50];
const frame = context.buildFlowFrame(previous, next);
assert.deepStrictEqual(Array.from(frame), [10, 20, 30, 40, 50], 'new sample should enter as the 52nd offscreen bar');
assert.deepStrictEqual(Array.from(context.settleFlowFrame(frame)), next, 'dropping the first slot after one-pitch scroll must settle to next history');
assert.strictEqual(context.buildFlowFrame(previous, [20, 31, 40, 50]), null, 'discontinuous history must rebase instead of scrolling');
assert.strictEqual(context.buildFlowFrame(previous, [20, 30, 40]), null, 'different history sizes must be rejected');
assert.strictEqual(context.settleFlowFrame([10]), null, 'short flow frame must be rejected');
assert.strictEqual(context.resolveFlowDuration(1000), 992, 'a 1 s sample cadence should leave less than one frame of headroom');
assert.strictEqual(context.smoothSampleInterval(1000, 1016), 1004, 'small daemon timing jitter should be smoothed instead of changing scroll speed abruptly');
assert.strictEqual(context.smoothSampleInterval(1004, 984), 999, 'the cadence filter should dampen a short interval fluctuation');
assert.strictEqual(context.smoothSampleInterval(1000, 1250), 1250, 'large intentional cadence changes should be adopted immediately');
assert.strictEqual(context.smoothSampleInterval(1000, NaN), 1000, 'invalid cadence samples should not poison the timing estimate');
assert.strictEqual(context.resolveFlowDuration(1015), 1007, 'animation duration should follow a slightly slower real sample cadence');
assert.strictEqual(context.resolveFlowDuration(900), 892, 'animation duration should follow a faster real sample cadence');
assert.strictEqual(context.resolveFlowDuration(300), 750, 'animation duration must respect its lower safety bound');
assert.strictEqual(context.resolveFlowDuration(2500), 1500, 'animation duration must respect its upper safety bound');
assert.strictEqual(context.resolveFlowDuration(NaN), 992, 'invalid sample cadence should use the nominal duration');
console.log('CPU graph flowing frame logic: OK');
NODE

python3 - "$CPU_GRAPH" "$FLOW_GRAPH" <<'PY'
from pathlib import Path
import sys
for name in sys.argv[1:]:
    source=Path(name).read_text(encoding='utf-8')
    pairs={')':'(',']':'[','}':'{'}; stack=[]; quote=None; escaped=False; line=False; block=False; i=0
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1<len(source) else ''
        if line:
            if c=='\n': line=False
            i+=1; continue
        if block:
            if c=='*' and n=='/': block=False; i+=2
            else: i+=1
            continue
        if quote:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line=True; i+=2; continue
        if c=='/' and n=='*': block=True; i+=2; continue
        if c in ('\"', "'"): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0]!=pairs[c]: raise SystemExit(f'{name}: unbalanced {c}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]}')
print('CPU graph QML delimiter balance: OK')
PY

echo 'CPU graph flowing test: OK'
