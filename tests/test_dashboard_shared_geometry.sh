#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/Dashboard.qml" "$ROOT/js/dashboard/DashboardCards.js" <<'PY'
from pathlib import Path
import re
import sys

qml = Path(sys.argv[1]).read_text()
cards = Path(sys.argv[2]).read_text()

# Each fixed-height InfoCard delegate must keep its own selected silhouette;
# it must never stretch vertically just because its sibling stack is taller.
def extract_qml_blocks(source: str, marker: str):
    blocks = []
    offset = 0
    while True:
        start = source.find(marker, offset)
        if start < 0:
            break
        brace = source.find('{', start)
        depth = 0
        end = None
        for index in range(brace, len(source)):
            if source[index] == '{':
                depth += 1
            elif source[index] == '}':
                depth -= 1
                if depth == 0:
                    end = index + 1
                    break
        assert end is not None, f'unclosed QML block for {marker}'
        blocks.append(source[start:end])
        offset = end
    return blocks

delegates = extract_qml_blocks(qml, 'delegate: InfoCard {')
assert len(delegates) == 3, f'expected 3 fixed-height InfoCard delegates, found {len(delegates)}'
for index, block in enumerate(delegates, 1):
    assert re.search(r'Layout\.fillWidth: true', block), f'delegate {index} must fill its column width'
    assert re.search(r'Layout\.fillHeight: false', block), f'delegate {index} must retain its selected height'
    assert re.search(r'Layout\.alignment: Qt\.AlignTop', block), f'delegate {index} must align to the top of its stack'
    if index == 1:
        assert re.search(r'Layout\.preferredHeight: DashboardCards\.cardHeight\(modelData\.id, Config\.dashboardCardSizes\)', block), \
            'horizontal peer cards must use their selected compact/expanded height'
    else:
        assert re.search(r'Layout\.preferredHeight: modelData\.id === cards\.spanningCardId', block), \
            f'delegate {index} must preserve shared/spanning card height calculation'

assert re.search(r'id: horizontalPeerColumnSlot[\s\S]*?Layout\.alignment: Qt\.AlignTop', qml), \
    'shorter Bento peer columns must remain top-aligned next to taller stacks'
assert re.search(r'Item \{\s*Layout\.fillHeight: !\(infoCard\.cardId === "today" && infoCard\.wideLead\)[\s\S]*?Layout\.preferredHeight: 0\s*\}', qml), \
    'card body must retain its flexible leading spacer'
assert 'var COMPACT_CARD_HEIGHTS = { today: 164, system: 164, network: 164, weather: 164, media: 164 }' in cards
assert 'var EXPANDED_CARD_HEIGHTS = { today: 208, system: 208, network: 208, weather: 208, media: 208 }' in cards
print('Dashboard shared card geometry, fixed card silhouettes and top-aligned stacks: PASS')
PY
