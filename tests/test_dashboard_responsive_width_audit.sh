#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const source = read('js/dashboard/DashboardCards.js')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.runInNewContext(source + `\nthis.api = {
  DEFAULT_IDS, DEFINITIONS, COLUMN_GAP, MIN_CARD_COLUMN_WIDTH,
  MIN_TWO_COLUMN_WIDTH, AUTO_TWO_COLUMN_WIDTH, NARROW_CARD_WIDTH,
  DEFAULT_DRAWER_MAX_WIDTH, DRAWER_SCREEN_INSET,
  columnsForWidth, drawerWidthForScreenWidth, resolveDashboardLayout
};`, context, { filename: 'js/dashboard/DashboardCards.js' });
const cards = context.api;
const dashboard = read('components/Dashboard.qml');

// The QML drawer has 16 px outer screen inset and 18 px content insets on
// each side. Check the actual card area, not just an arbitrary helper width.
assert.match(dashboard, /Number\(configuredGeometry\[2\]\) > 0 \? Number\(configuredGeometry\[2\]\) : DashboardCards\.drawerWidthForScreenWidth\(parent\.width\)/,
  'automatic width retains the established responsive screen-based drawer size');
assert.match(dashboard, /readonly property real targetX: Number\(configuredGeometry\[0\]\) > -10000/,
  'drawer supports the configured X coordinate');
assert.match(dashboard, /Math\.max\(16, parent\.width - width - 16\)/,
  'default placement preserves the established 16px right screen inset');
assert.match(dashboard, /anchors\.margins: 18/);
const cardAreaForScreen = screenWidth => cards.drawerWidthForScreenWidth(screenWidth) - 36;
const boundaryCases = [
  { screen: 537, area: 469, auto: 1, two: 1 },
  { screen: 538, area: 470, auto: 1, two: 2 },
  { screen: 567, area: 499, auto: 1, two: 2 },
  { screen: 568, area: 500, auto: 2, two: 2 },
  { screen: 592, area: 524, auto: 2, two: 2 }
];
for (const item of boundaryCases) {
  const area = cardAreaForScreen(item.screen);
  assert.strictEqual(area, item.area, `screen ${item.screen}px resolves to ${item.area}px card area`);
  assert.strictEqual(cards.columnsForWidth('auto', area), item.auto,
    `auto mode breakpoint is correct at ${item.screen}px screen width`);
  assert.strictEqual(cards.columnsForWidth('two', area), item.two,
    `explicit two-column fallback is correct at ${item.screen}px screen width`);
  assert.strictEqual(cards.columnsForWidth('one', area), 1,
    `one-column mode remains stable at ${item.screen}px screen width`);
}

// At the explicit two-column threshold, the real card tracks must not be
// squeezed below their declared readable minimum after applying the gutter.
assert.strictEqual(cards.MIN_CARD_COLUMN_WIDTH, 230);
assert.strictEqual(cards.COLUMN_GAP, 6);
assert.strictEqual(cards.MIN_TWO_COLUMN_WIDTH, 470);
const minTrackWidth = (cards.MIN_TWO_COLUMN_WIDTH - cards.COLUMN_GAP) / 2;
assert.strictEqual(minTrackWidth, 232);
assert.ok(minTrackWidth >= cards.MIN_CARD_COLUMN_WIDTH,
  'explicit two-column mode preserves at least the 230px minimum card width');
assert.strictEqual(cards.AUTO_TWO_COLUMN_WIDTH, 500,
  'automatic mode waits for the wider 500px breakpoint');
assert.strictEqual(cards.NARROW_CARD_WIDTH, 270);
assert.match(dashboard, /readonly property bool narrow: width < DashboardCards\.NARROW_CARD_WIDTH/,
  'cards switch to the denser typography below the 270px content width');
assert.match(dashboard, /infoCard\.narrow \? DashboardCards\.CARD_DETAIL_TEXT_NARROW_SIZE/,
  'secondary card text uses the narrow typography scale');

function permutations(items) {
  if (items.length <= 1) return [items.slice()];
  const result = [];
  for (let index = 0; index < items.length; index++) {
    const tail = items.slice(0, index).concat(items.slice(index + 1));
    for (const rest of permutations(tail)) result.push([items[index], ...rest]);
  }
  return result;
}
function ids(layout) {
  if (layout.kind === 'wide-lead-horizontal')
    return Array.from(layout.lead.concat(layout.peers), item => item.id);
  return Array.from(layout.left.concat(layout.right), item => item.id);
}
function verify(layout, expected, mode, width) {
  const assigned = ids(layout);
  assert.strictEqual(assigned.length, expected.length,
    'responsive transition assigns the expected number of cards');
  assert.deepStrictEqual(assigned.slice().sort(), expected.map(item => item.id).sort(),
    'responsive transition keeps each visible card exactly once');
  assert.strictEqual(new Set(assigned).size, expected.length,
    'responsive transition does not leave stale duplicate delegates');
  if (layout.kind === 'wide-lead-horizontal') {
    assert.deepStrictEqual(Array.from(layout.lead, item => item.id), [expected[0].id]);
    assert.deepStrictEqual(Array.from(layout.peers, item => item.id), expected.slice(1).map(item => item.id));
    assert.strictEqual(layout.left.length + layout.right.length, 0,
      'horizontal state clears both inactive vertical models');
  } else {
    assert.strictEqual(layout.lead.length + layout.peers.length, 0,
      'vertical state clears both inactive horizontal models');
  }
  const expectedKind = expected.length === 0 ? 'empty'
    : cards.columnsForWidth(mode, width) === 1 ? 'single'
      : expected.length >= 3 && width >= 500 ? 'wide-lead-horizontal'
        : expected.length === 3 ? 'three-vertical'
          : expected.length === 1 ? 'single' : 'balanced';
  assert.strictEqual(layout.kind, expectedKind,
    'transition kind matches the current screen width and configured column mode');
}

const widths = [469, 470, 499, 500, 499, 470, 469];
let transitionCount = 0;
for (let mask = 1; mask < (1 << cards.DEFINITIONS.length); mask++) {
  const visible = Array.from(cards.DEFINITIONS).filter((_, index) => mask & (1 << index));
  for (const order of permutations(visible)) {
    for (const mode of ['auto', 'two']) {
      for (const width of widths) {
        const layout = cards.resolveDashboardLayout(order, mode, width, {}, cards.COLUMN_GAP);
        verify(layout, order, mode, width);
        transitionCount++;
      }
    }
  }
}
assert.strictEqual(transitionCount, 4550,
  'all configured visible sets/orders cross both responsive breakpoints in both directions');

// Scrolling remains bound to the exact responsive content width and height;
// changing columns or screen width cannot leave an obsolete scroll position.
assert.match(dashboard, /contentWidth: width/);
assert.match(dashboard, /contentHeight: cards\.implicitHeight/);
assert.match(dashboard, /onWidthChanged: root\.scheduleDashboardLayoutSync\(\)/);
assert.match(dashboard, /DashboardCards\.clampScrollPosition\(/);
console.log(`Dashboard responsive screen-width audit: ${boundaryCases.length} real-screen boundaries and ${transitionCount} ordered transitions passed`);
NODE
