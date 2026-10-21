#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Graph lazy mode instantiation: FAIL: $*" >&2; exit 1; }

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
cpu = (root / 'components/CpuGraph.qml').read_text()
cava = (root / 'components/Cava.qml').read_text()
primitive = (root / 'components/primitives/SegmentBarGraph.qml').read_text()

def need(condition, message):
    if not condition:
        raise SystemExit('Graph lazy mode instantiation: FAIL: ' + message)

def component_body(source, component_id):
    match = re.search(r'Component\s*\{\s*id\s*:\s*' + re.escape(component_id) + r'\b', source)
    need(match is not None, f'missing Component {component_id}')
    opening = source.find('{', match.start())
    depth = 0; quote = None; escaped = False; line_comment = False; block_comment = False; i = opening
    while i < len(source):
        c = source[i]; n = source[i+1] if i+1 < len(source) else ''
        if line_comment:
            if c == '\n': line_comment = False
            i += 1; continue
        if block_comment:
            if c == '*' and n == '/': block_comment = False; i += 2
            else: i += 1
            continue
        if quote:
            if escaped: escaped = False
            elif c == '\\': escaped = True
            elif c == quote: quote = None
            i += 1; continue
        if c == '/' and n == '/': line_comment = True; i += 2; continue
        if c == '/' and n == '*': block_comment = True; i += 2; continue
        if c in ('"', "'"): quote = c; i += 1; continue
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return source[opening+1:i]
        i += 1
    raise SystemExit(f'Graph lazy mode instantiation: FAIL: unclosed Component {component_id}')

for source, name, mode_prop in ((cpu, 'CpuGraph', 'cpuGraphMode'), (cava, 'Cava', 'cavaMode')):
    need(source.count('Loader {') == 1, f'{name} should have one active-mode Loader')
    need('sourceComponent: Config.' + mode_prop + ' === "both" ? bothModeComponent' in source,
         f'{name} loader does not select both-mode component')
    need('Config.' + mode_prop + ' === "top" ? topModeComponent' in source,
         f'{name} loader does not select top-mode component')
    need('Config.' + mode_prop + ' === \"bottom\" ? bottomModeComponent' in source, f'{name} does not select bottom-mode component')
    need(not re.search(r'visible\s*:\s*Config\.' + mode_prop, source),
         f'{name} still creates mode trees and only hides inactive ones')
    if name == 'Cava':
        need('active: !Config.cavaHideWhenSilent || root.soundActive' in source,
             'CAVA hide-when-silent should release graph delegates after the grace period')
    counts = {}
    for mode in ('bothModeComponent', 'topModeComponent', 'bottomModeComponent'):
        body = component_body(source, mode)
        counts[mode] = body.count('Primitives.SegmentBarGraph {')
    need(counts == {'bothModeComponent': 2, 'topModeComponent': 1, 'bottomModeComponent': 1},
         f'{name} graph counts per mode are unexpected: {counts}')

need('root.barCount > 0' in primitive, 'slot widths should be based on the requested bar count')
need('(barRow.width - (root.barCount - 1) * root.spacing) / root.barCount' in primitive,
     'slot width formula still follows incoming value-array length and can jump on partial samples')
need('root.values.length - 1' not in primitive, 'old sample-length based slot calculation remains')
print('Graph lazy mode instantiation: OK')
print('Active graph renderers: CPU graph 2 in both mode / 1 in one-sided modes; CAVA 2 / 1.')
PY
