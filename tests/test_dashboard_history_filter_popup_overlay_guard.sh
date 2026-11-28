#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const popupStart = dash.indexOf('id: historyAppFilterPopup');
assert(popupStart >= 0, 'history app-filter popup exists');
const popup = dash.slice(popupStart, dash.indexOf('\n            }', popupStart) + 14);
function propertyBlock(name) {
  const start = popup.indexOf(`${name}: {`);
  assert(start >= 0, `${name} geometry binding exists`);
  const open = popup.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < popup.length; i++) {
    if (popup[i] === '{') depth++;
    else if (popup[i] === '}' && --depth === 0) return popup.slice(start, i + 1);
  }
  throw new Error(`${name} geometry binding is not closed`);
}
const x = propertyBlock('x');
const y = propertyBlock('y');
for (const [name, block, dimension] of [['x', x, 'width'], ['y', y, 'height']]) {
  assert(block.includes('var overlayItem = Overlay.overlay'), `${name} binding captures overlay once`);
  assert(block.includes('if (!overlayItem || !anchorItem) return 8'), `${name} binding guards null overlay/anchor before mapping`);
  assert(block.includes('if (!point) return 8'), `${name} binding guards invalid mapped point`);
  assert(block.includes(`overlayItem.${dimension}`), `${name} binding reads guarded overlay ${dimension}`);
  assert(block.indexOf('if (!overlayItem || !anchorItem) return 8') < block.indexOf(`overlayItem.${dimension}`), `${name} null guard precedes ${dimension} access`);
  assert(!block.includes(`Overlay.overlay.${dimension}`), `${name} binding does not dereference attached overlay directly`);
}
assert(y.includes('Math.max(8 * popupScale,'), 'popup vertical placement keeps the scaled top margin');
console.log('Dashboard history filter popup null-overlay geometry guards: OK');
JS
