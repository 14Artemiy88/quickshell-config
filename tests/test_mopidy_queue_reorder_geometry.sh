#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/mopidy/QueueReorderGeometry.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const helper = {};
vm.runInNewContext(source, helper, { filename: 'QueueReorderGeometry.js' });
const queueItems = [
  { kind: 'album', startIndex: 0, endIndex: 1 },
  { kind: 'track', queueIndex: 0 },
  { kind: 'track', queueIndex: 1 },
  { kind: 'album', startIndex: 2, endIndex: 3 },
  { kind: 'track', queueIndex: 2 },
  { kind: 'track', queueIndex: 3 },
  { kind: 'album', startIndex: 4, endIndex: 4 },
  { kind: 'track', queueIndex: 4 }
];
const displays = [1, 2, 4, 5, 7];
const expected = [0, 2, 3, 5, 6];
for (let i = 0; i < expected.length; i++) {
  const actual = helper.insertionAnchorDisplayIndex(queueItems, displays, i);
  if (actual !== expected[i])
    throw new Error(`track ${i} should anchor at display ${expected[i]}, got ${actual}`);
}
if (helper.insertionAnchorDisplayIndex(queueItems, displays, -1) !== -1)
  throw new Error('negative track index must be rejected');
if (helper.insertionAnchorDisplayIndex(queueItems, displays, 5) !== -1)
  throw new Error('out-of-range track index must be rejected');
if (helper.insertionAnchorDisplayIndex(queueItems, displays, 2, 3) !== 4)
  throw new Error('reordering within one album must insert after its shared header');
if (helper.insertionAnchorDisplayIndex(queueItems, displays, 2, 0) !== 3)
  throw new Error('moving into another album must insert before the target album header');
if (helper.insertionAnchorDisplayIndex(queueItems, displays, 3, 4) !== 5)
  throw new Error('moving before a non-first track must target its actual row gap');
if (helper.albumHeaderDisplayIndex(queueItems, 3) !== 3)
  throw new Error('source track lookup must resolve its actual album segment');
if (helper.gapCenterBefore(40, 2) !== 39)
  throw new Error('before-first gap should use half spacing');
if (helper.gapCenterBetween(38, 42) !== 40)
  throw new Error('internal gap should use actual adjacent row edges');
if (helper.gapCenterAfter(40, 2) !== 41)
  throw new Error('after-last gap should use half spacing');
console.log('Mopidy queue album-header-aware reorder geometry: OK');
NODE

MAIN="$ROOT/components/mopidy/Mopidy.qml"
QUEUE="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
PLAYLIST="$ROOT/components/mopidy/MopidyPlaylistContents.qml"
grep -Fq 'QueueReorderGeometry.insertionAnchorDisplayIndex' "$MAIN"
grep -Fq 'refreshDropTargetForLayoutChange()' "$MAIN"
grep -Fq 'cacheBuffer: root.queueReorderDragging ? contentHeight : height * 2' "$MAIN"
grep -Fq 'interactive: !root.queueReorderDragging' "$MAIN"
grep -Fq 'property alias queueReorderHost: queueReorderOverlay' "$MAIN"
grep -Fq 'id: queueReorderOverlay' "$MAIN"
grep -Fq 'z: 30' "$MAIN"
grep -Fq 'dropIndicatorHost: controller.queueReorderHost' "$QUEUE"
grep -Fq 'controller.queueActiveDragHandle === queueReorderHandle' "$QUEUE"
grep -Fq 'trackId < 0' "$MAIN"
grep -Fq 'tlid >= 0' "$MAIN"
grep -Fq 'controller.playlistContentActiveDragHandle === playlistContentReorderHandle' "$PLAYLIST"
grep -Fq 'Сохранение порядка…' "$PLAYLIST"
grep -Fq 'cacheBuffer: controller.playlistContentReorderDragging ? contentHeight : height * 2' "$PLAYLIST"
grep -Fq 'interactive: !controller.playlistContentReorderDragging' "$PLAYLIST"
python3 - "$QUEUE" "$PLAYLIST" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for filename in sys.argv[1:]:
    text=Path(filename).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i<len(text):
        c=text[i]; n=text[i+1] if i+1<len(text) else ''
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
            if not stack or stack[-1][0]!=pairs[c]: raise SystemExit(f'{filename}: unexpected {c} at {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{filename}: unclosed {stack[-1][0]} at {stack[-1][1]}')
print('Mopidy drag-reorder QML delimiter checks: OK')
PYCODE
