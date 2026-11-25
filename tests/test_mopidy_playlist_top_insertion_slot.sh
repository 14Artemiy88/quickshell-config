#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$ROOT/components/mopidy/MopidyPlaylistContents.qml"
HELPER="$ROOT/js/utils/DragReorder.js"

python3 - "$VIEW" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding='utf-8')
assert 'header: Item {' in source, 'saved playlist must reserve a visible top insertion gutter'
assert 'id: playlistItemsTopInsertionGutter' in source, 'top insertion gutter needs a stable id'
assert 'height: 4' in source, 'top insertion gutter should be 4px high'
assert 'playlistItemsView.itemAtIndex(index)' in source, 'playlist reorder geometry should prefer real delegate coordinates'
assert 'delegate.mapToItem(host, 0, 0)' in source, 'materialized playlist row must map into the indicator host'
assert 'playlistItemsTopInsertionGutter.height' in source, 'virtualized fallback geometry must include the top gutter'
assert 'dropIndicatorHost: playlistItemsView' in source, 'playlist insertion indicator must stay in the clipped viewport'
print('Mopidy saved-playlist first insertion slot contract: OK')
PYCODE

node - "$HELPER" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '');
const helper = {};
vm.runInNewContext(source, helper);
const gutter = 4;
const spacing = 2;
const firstRowTop = gutter; // ListView headers are directly adjacent to delegate items.
const center = helper.insertionGapCenter(NaN, firstRowTop, spacing, 'before');
const lineY = center - 1;
if (lineY < 0 || lineY + 2 > gutter)
  throw new Error(`top insertion marker (${lineY}..${lineY + 2}) is not fully inside 0..${gutter}px gutter`);
if (center !== 3 || lineY !== 2)
  throw new Error(`unexpected first-slot geometry: center=${center}, y=${lineY}`);
console.log('Mopidy saved-playlist top insertion geometry: visible and unclipped');
NODE
