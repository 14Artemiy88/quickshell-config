#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
function read(relative) { return fs.readFileSync(path.join(root, relative), 'utf8'); }
function load(relative, append = '', globals = {}) {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
  const context = { ...globals };
  vm.runInNewContext(source + '\n' + append, context, { filename: relative });
  return context;
}

const cards = load('js/dashboard/DashboardCards.js',
  'this.api = { CARD_SIZE_MODES, DEFINITIONS, DEFAULT_IDS, normalizeCardSizeMode, normalizeCardSizes, setCardSize, cardSizeMode, cardSizeModeIndex, cardHeight, balancedColumns, threeCardOrientation, threeCardHorizontalRowHeight, threeCardHorizontalHeight, wideLeadPeerColumns, wideLeadHorizontalHeight, stackHeight, normalizeOrder, move, setEnabled, orderedVisible, columnsForWidth, drawerWidthForScreenWidth, resolveDashboardLayout, clampScrollPosition, COLUMN_GAP, THREE_CARD_HORIZONTAL_WIDTH, WIDE_LEAD_GROUP_GAP, WIDE_LEAD_CARD_PADDING, DRAWER_SCREEN_INSET, DEFAULT_DRAWER_MAX_WIDTH };').api;
assert.deepStrictEqual(Array.from(cards.CARD_SIZE_MODES), ['compact', 'expanded']);
assert.strictEqual(cards.WIDE_LEAD_GROUP_GAP, 14, 'wide Bento leads use a compact shared content-group gutter');
assert.strictEqual(cards.WIDE_LEAD_CARD_PADDING, 8, 'wide lead content sits closer to the card edge without changing normal card padding');
assert.strictEqual(cards.normalizeCardSizeMode('expanded'), 'expanded');
assert.strictEqual(cards.normalizeCardSizeMode('wide'), 'compact');
assert.strictEqual(cards.clampScrollPosition(420, 300, 500), 0,
  'shrinking Bento content below the viewport resets an obsolete scroll offset to the top');
assert.strictEqual(cards.clampScrollPosition(420, 760, 400), 360,
  'shrinking content clamps scroll position to the new maximum instead of leaving blank space');
assert.strictEqual(cards.clampScrollPosition(180, 900, 400), 180,
  'layout changes preserve a scroll position that remains within the new content bounds');
assert.strictEqual(cards.clampScrollPosition(-40, 900, 400), 0,
  'scroll position never becomes negative after a viewport resize');
assert.strictEqual(cards.clampScrollPosition(Number.NaN, 900, 400), 0,
  'invalid startup scroll measurements safely resolve to the top');
assert.deepStrictEqual(JSON.parse(JSON.stringify(cards.normalizeCardSizes(undefined))), {
  today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'compact'
}, 'legacy profiles default every card independently to compact');
assert.deepStrictEqual(JSON.parse(JSON.stringify(cards.normalizeCardSizes({ system: 'expanded', network: 'bad', weather: 'compact' }))), {
  today: 'compact', system: 'expanded', network: 'compact', weather: 'compact', media: 'compact'
}, 'invalid and missing size entries fall back independently');
const mediaExpanded = cards.setCardSize({ system: 'expanded' }, 'media', 'expanded');
assert.deepStrictEqual(JSON.parse(JSON.stringify(mediaExpanded)), {
  today: 'compact', system: 'expanded', network: 'compact', weather: 'compact', media: 'expanded'
}, 'setting one card size does not modify any peer card');
assert.strictEqual(cards.setCardSize(mediaExpanded, 'unknown', 'expanded').media, 'expanded', 'unknown card ids are ignored');
assert.strictEqual(cards.cardSizeModeIndex(mediaExpanded, 'media'), 1);
assert.strictEqual(cards.cardHeight('today', { today: 'compact' }), 164, 'compact Today card uses the shared 164px silhouette');
assert.strictEqual(cards.cardHeight('today', { today: 'expanded' }), 208);
assert.strictEqual(cards.cardHeight('system', { system: 'compact' }), 164, 'compact system height uses the shared 164px silhouette');
assert.strictEqual(cards.cardHeight('system', { system: 'expanded' }), 208);
assert.strictEqual(cards.cardHeight('network', { network: 'expanded' }), 208);
assert.strictEqual(cards.cardHeight('media', { media: 'expanded' }), 208);
assert.strictEqual(cards.cardHeight('weather', { weather: 'compact' }), 164, 'compact weather height uses the shared 164px silhouette');
assert.strictEqual(cards.cardHeight('weather', { weather: 'expanded' }), 208);

const allDefinitions = Array.from(cards.DEFINITIONS);
assert.strictEqual(allDefinitions.length, 5, 'Today joins the four module cards as an independently managed Dashboard card');
assert.strictEqual(allDefinitions[0].id, 'today', 'Today is the first default card');
const fiveDefaultCards = cards.orderedVisible(cards.normalizeOrder(cards.DEFAULT_IDS), cards.DEFAULT_IDS);
assert.deepStrictEqual(Array.from(fiveDefaultCards, card => card.id), ['today', 'system', 'network', 'weather', 'media']);
const fiveCardLayout = cards.resolveDashboardLayout(fiveDefaultCards, 'auto', 900, {}, 10);
assert.strictEqual(fiveCardLayout.kind, 'wide-lead-horizontal', 'five enabled cards retain a full-width leading card in the wide Bento layout');
assert.deepStrictEqual(Array.from(fiveCardLayout.lead, card => card.id), ['today'],
  'Today is the full-width first card in the default five-card Dashboard');
assert.deepStrictEqual(Array.from(fiveCardLayout.peers, card => card.id), ['system', 'network', 'weather', 'media'],
  'all remaining cards preserve configured order beneath the lead');
const fivePeerColumns = cards.wideLeadPeerColumns(fiveCardLayout.peers, {}, 10);
assert.deepStrictEqual(Array.from(fivePeerColumns.left, card => card.id), ['system', 'weather']);
assert.deepStrictEqual(Array.from(fivePeerColumns.right, card => card.id), ['network', 'media']);
assert.strictEqual(heightOf(fivePeerColumns.left, {}), heightOf(fivePeerColumns.right, {}),
  'four lower cards form two equally tall balanced stacks');
let fiveCustomOrder = cards.normalizeOrder(['system', 'network', 'today', 'weather', 'media']);
fiveCustomOrder = cards.move(fiveCustomOrder, 'today', -1);
fiveCustomOrder = cards.move(fiveCustomOrder, 'today', -1);
const fiveCustomLayout = cards.resolveDashboardLayout(
  cards.orderedVisible(fiveCustomOrder, cards.DEFAULT_IDS), 'auto', 900, {}, 10);
assert.strictEqual(fiveCustomLayout.lead[0].id, 'today',
  'moving Today to the first configured position makes it the wide lead even with all five cards enabled');
assert.strictEqual(cards.wideLeadHorizontalHeight(fiveCardLayout.lead.concat(fiveCardLayout.peers), {}, 10), 512,
  'five compact cards account for the lead row and two balanced lower stacks');
const mixedFiveSizes = { today: 'compact', system: 'expanded', network: 'compact', weather: 'expanded', media: 'compact' };
const mixedFivePeers = cards.wideLeadPeerColumns(fiveCardLayout.peers, mixedFiveSizes, 10);
const mixedFivePeerHeight = Math.max(
  cards.stackHeight(mixedFivePeers.left, mixedFiveSizes, 10),
  cards.stackHeight(mixedFivePeers.right, mixedFiveSizes, 10)
);
assert.strictEqual(cards.wideLeadHorizontalHeight(fiveCardLayout.lead.concat(fiveCardLayout.peers), mixedFiveSizes, 10),
  cards.cardHeight('today', mixedFiveSizes) + 10 + mixedFivePeerHeight,
  'a compact lead is not stretched to the expanded peer track in the five-card Bento');
assert.deepStrictEqual(
  Array.from([...fiveCardLayout.lead, ...fivePeerColumns.left, ...fivePeerColumns.right], card => card.id).sort(),
  ['media', 'network', 'system', 'today', 'weather'],
  'the five-card lead and its lower columns render every card exactly once');
const definitions = allDefinitions.filter(card => card.id !== 'today');
function heightOf(column, sizes) {
  return column.reduce((sum, card) => sum + cards.cardHeight(card.id, sizes), 0)
    + Math.max(0, column.length - 1) * 10;
}
const allCompact = cards.balancedColumns(definitions, {}, 10);
assert.deepStrictEqual(Array.from(allCompact.left, card => card.id), ['system', 'weather'],
  'the default two-column layout keeps the expected row-major visual order');
assert.deepStrictEqual(Array.from(allCompact.right, card => card.id), ['network', 'media']);
assert.strictEqual(heightOf(allCompact.left, {}), heightOf(allCompact.right, {}),
  'default compact cards form two equally tall vertical stacks');
const diagonalExpanded = cards.balancedColumns(definitions, {
  today: 'compact', system: 'expanded', network: 'compact', weather: 'compact', media: 'expanded'
}, 10);
assert.deepStrictEqual(Array.from(diagonalExpanded.left, card => card.id), ['system', 'weather']);
assert.deepStrictEqual(Array.from(diagonalExpanded.right, card => card.id), ['network', 'media']);
assert.ok(Math.abs(heightOf(diagonalExpanded.left, { system: 'expanded', media: 'expanded' })
  - heightOf(diagonalExpanded.right, { system: 'expanded', media: 'expanded' })) <= 4,
  'diagonally expanded cards keep the two complete columns within four pixels of equal height');

const threeCompact = cards.resolveDashboardLayout(definitions.slice(0, 3), 'two', 499, {}, 10);
assert.strictEqual(threeCompact.kind, 'three-vertical');
assert.deepStrictEqual(Array.from(threeCompact.left, card => card.id), ['system'],
  'three-card Bento keeps its vertical composition just below the horizontal threshold in explicit two-column mode');
assert.deepStrictEqual(Array.from(threeCompact.right, card => card.id), ['network', 'weather'],
  'the other two configured cards remain stacked in order in the compact vertical composition');
assert.strictEqual(cards.stackHeight(threeCompact.right, {}, 10), 338,
  'a compact spanning card matches the combined height of two compact cards and their gutter');
assert.strictEqual(cards.stackHeight(threeCompact.right, { network: 'expanded', weather: 'compact' }, 10), 382,
  'the spanning height respects independent compact and expanded sizes');
assert.strictEqual(cards.stackHeight([], {}, 10), 0, 'empty stacks have no height');
assert.strictEqual(cards.THREE_CARD_HORIZONTAL_WIDTH, 500, 'horizontal Bento uses the established minimum width for automatic two-column layout');
assert.strictEqual(cards.threeCardOrientation(499), 'vertical', 'three cards keep the vertical Bento layout immediately below the horizontal threshold');
assert.strictEqual(cards.threeCardOrientation(500), 'horizontal', 'three cards use a horizontal Bento layout once the card area supports automatic two columns');
assert.strictEqual(cards.threeCardOrientation(524), 'horizontal', 'the normal 560px drawer supports horizontal Bento without widening');
const standardDrawerCardArea = cards.DEFAULT_DRAWER_MAX_WIDTH - 36;
assert.strictEqual(standardDrawerCardArea, 524, 'the normal drawer provides a 524px card area after its two 18px inner margins');
assert.strictEqual(cards.columnsForWidth('auto', standardDrawerCardArea), 2,
  'the normal drawer card area still supports automatic two-column layout');
assert.strictEqual(cards.resolveDashboardLayout(definitions.slice(0, 3), 'auto', standardDrawerCardArea, {}, 10).kind,
  'wide-lead-horizontal', 'horizontal Bento is reachable at the normal drawer width with no panel expansion');
assert.strictEqual(cards.threeCardOrientation(NaN), 'vertical', 'invalid widths safely use the vertical Bento layout');
assert.strictEqual(cards.drawerWidthForScreenWidth(1920), 560,
  'wide screens keep the established 560px drawer maximum');
assert.strictEqual(cards.drawerWidthForScreenWidth(700), 560,
  'three-card horizontal Bento does not widen the drawer on medium displays');
assert.strictEqual(cards.drawerWidthForScreenWidth(788), 560,
  'a wide monitor does not cause the Dashboard panel to expand beyond its normal width');
assert.strictEqual(cards.drawerWidthForScreenWidth(550), 518,
  'narrow screens constrain the drawer while preserving 16px outer margins');
assert.strictEqual(cards.drawerWidthForScreenWidth(NaN), 1,
  'invalid screen widths fall back to a safe positive drawer width');
assert.strictEqual(cards.threeCardHorizontalHeight(definitions.slice(0, 3), {}, 10), 338,
  'compact horizontal Bento height is one card plus a row of two cards and a gutter');
assert.strictEqual(cards.threeCardHorizontalRowHeight(definitions.slice(0, 3), {}), 164,
  'all-compact horizontal Bento rows share the compact silhouette height');
assert.strictEqual(cards.threeCardHorizontalHeight(definitions.slice(0, 3), {
  system: 'expanded', network: 'expanded', weather: 'compact'
}, 10), 426,
  'horizontal Bento uses equal row tracks when the lead and one peer are expanded');
assert.strictEqual(cards.threeCardHorizontalRowHeight(definitions.slice(0, 3), {
  system: 'compact', network: 'expanded', weather: 'compact'
}), 164, 'the lead row follows the configured lead card size instead of expanding for a peer');
assert.strictEqual(cards.threeCardHorizontalHeight(definitions.slice(0, 3), {
  system: 'compact', network: 'expanded', weather: 'compact'
}, 10), 382, 'a compact lead is followed by a naturally sized expanded peer row with only the configured gutter');
assert.strictEqual(cards.threeCardHorizontalHeight(definitions.slice(0, 3), {
  system: 'expanded', network: 'compact', weather: 'compact'
}, 10), 382, 'an expanded lead does not stretch the compact peer row');
assert.strictEqual(cards.threeCardHorizontalHeight(definitions.slice(0, 3), {
  system: 'compact', network: 'compact', weather: 'compact'
}, 10), 338, 'uniform compact cards retain their previous total height');
const fourCardLayout = cards.resolveDashboardLayout(definitions, 'auto', 900, {}, 10);
assert.strictEqual(fourCardLayout.kind, 'wide-lead-horizontal', 'four visible cards also keep the first configured card as a full-width lead');
assert.deepStrictEqual(Array.from(fourCardLayout.lead, card => card.id), ['system']);
assert.deepStrictEqual(Array.from(fourCardLayout.peers, card => card.id), ['network', 'weather', 'media']);
const fourPeerColumns = cards.wideLeadPeerColumns(fourCardLayout.peers, {}, 10);
assert.deepStrictEqual(Array.from(fourPeerColumns.left, card => card.id), ['network', 'media']);
assert.deepStrictEqual(Array.from(fourPeerColumns.right, card => card.id), ['weather']);
assert.strictEqual(cards.resolveDashboardLayout(fiveDefaultCards, 'two', 499, {}, 10).kind, 'balanced',
  'five cards use the normal balanced columns below the wide-lead breakpoint');
function permutations(items) {
  if (items.length <= 1) return [items.slice()]
  const result = []
  for (let index = 0; index < items.length; ++index) {
    const head = items[index]
    const tail = items.slice(0, index).concat(items.slice(index + 1))
    for (const rest of permutations(tail)) result.push([head, ...rest])
  }
  return result
}

// Exercise every possible set/order of three visible cards and every
// compact/expanded combination. The lead row follows only the lead card,
// while the peer row follows the taller of its naturally sized columns.
for (let omittedIndex = 0; omittedIndex < definitions.length; ++omittedIndex) {
  const visibleSet = definitions.filter((card, index) => index !== omittedIndex)
  for (const order of permutations(visibleSet)) {
    const ordered = order.map(card => definitions.find(item => item.id === card.id))
    const layout = cards.resolveDashboardLayout(ordered, 'auto', 500, {}, 10)
    assert.strictEqual(layout.kind, 'wide-lead-horizontal',
      'the standard drawer card area resolves to the compact horizontal Bento composition')
    assert.deepStrictEqual(Array.from(layout.lead, card => card.id), [order[0].id],
      'the first configured card becomes the full-width horizontal Bento lead for every visibility/order combination')
    assert.deepStrictEqual(Array.from(layout.peers, card => card.id), order.slice(1).map(card => card.id),
      'the remaining visible cards preserve their configured order in the lower row')

    for (let mask = 0; mask < 8; ++mask) {
      const sizes = {}
      ordered.forEach((card, index) => {
        sizes[card.id] = (mask & (1 << index)) ? 'expanded' : 'compact'
      })
      const expectedLeadHeight = cards.cardHeight(ordered[0].id, sizes)
      const peerColumns = cards.wideLeadPeerColumns(ordered.slice(1), sizes, 10)
      const expectedPeerHeight = Math.max(
        cards.stackHeight(peerColumns.left, sizes, 10),
        cards.stackHeight(peerColumns.right, sizes, 10)
      )
      assert.strictEqual(cards.threeCardHorizontalRowHeight(ordered, sizes), expectedLeadHeight,
        'lead row follows the configured lead card size only')
      assert.strictEqual(cards.threeCardHorizontalHeight(ordered, sizes, 10), expectedLeadHeight + expectedPeerHeight + 10,
        'horizontal Bento height is the actual lead height plus the taller peer stack and one gutter')
      ordered.forEach(card => {
        const selectedHeight = cards.cardHeight(card.id, sizes)
        assert.ok(selectedHeight === 164 || selectedHeight === 208,
          'shared row tracks do not alter each card’s independent compact/expanded silhouette')
      })
    }
  }
}

// Exercise live layout transitions across width, order and visibility. The
// same resolver is used by Dashboard.qml, so each state must assign every
// visible card exactly once and leave every inactive Repeater model empty.
function permutations(items) {
  if (items.length <= 1) return [items.slice()]
  const result = []
  for (let index = 0; index < items.length; ++index) {
    const head = items[index]
    const tail = items.slice(0, index).concat(items.slice(index + 1))
    for (const rest of permutations(tail)) result.push([head, ...rest])
  }
  return result
}
function assignedIds(layout) {
  if (layout.kind === 'wide-lead-horizontal')
    return Array.from(layout.lead.concat(layout.peers), card => card.id)
  return Array.from(layout.left.concat(layout.right), card => card.id)
}
function assertLayoutState(layout, ordered, mode, width) {
  const expectedColumns = cards.columnsForWidth(mode, width)
  assert.strictEqual(layout.columns, expectedColumns,
    'resolved layout tracks the current auto/one/two-column width breakpoint')
  const expectedKind = ordered.length === 0 ? 'empty'
    : expectedColumns === 1 ? 'single'
      : ordered.length >= 3 && width >= cards.THREE_CARD_HORIZONTAL_WIDTH ? 'wide-lead-horizontal'
        : ordered.length === 3 ? 'three-vertical' : ordered.length === 1 ? 'single' : 'balanced';
  assert.strictEqual(layout.kind, expectedKind,
    'layout kind is recomputed from the current visibility count, column mode and width')
  const assigned = assignedIds(layout)
  assert.strictEqual(assigned.length, ordered.length,
    'active layout models contain exactly as many cards as the visible set')
  assert.deepStrictEqual(assigned.slice().sort(), Array.from(ordered, card => card.id).sort(),
    'every visible card is assigned exactly once with no stale or duplicate delegate')

  if (layout.kind === 'wide-lead-horizontal') {
    assert.deepStrictEqual(Array.from(layout.lead, card => card.id), [ordered[0].id],
      'horizontal lead follows the first currently visible configured card')
    assert.deepStrictEqual(Array.from(layout.peers, card => card.id), Array.from(ordered.slice(1), card => card.id),
      'horizontal peers follow the current configured order')
    assert.strictEqual(layout.left.length + layout.right.length, 0,
      'horizontal transition clears both normal vertical Repeater models')
    const peerColumns = cards.wideLeadPeerColumns(layout.peers, {}, 10)
    const peerIds = Array.from(peerColumns.left.concat(peerColumns.right), card => card.id)
    assert.strictEqual(peerIds.length, ordered.length - 1,
      'wide lead lower columns assign every peer exactly once')
    assert.deepStrictEqual(peerIds.slice().sort(), Array.from(ordered.slice(1), card => card.id).sort(),
      'wide lead lower columns contain the complete peer set')
    assert.ok(peerColumns.left.length > 0 && peerColumns.right.length > 0,
      'wide lead keeps remaining cards in two lower columns')
  } else if (layout.kind === 'three-vertical') {
    assert.deepStrictEqual(Array.from(layout.left, card => card.id), [ordered[0].id],
      'vertical span follows the first currently visible configured card')
    assert.deepStrictEqual(Array.from(layout.right, card => card.id), Array.from(ordered.slice(1), card => card.id),
      'vertical peers follow the current configured order')
    assert.strictEqual(layout.lead.length + layout.peers.length, 0,
      'vertical transition clears both horizontal Repeater models')
  } else {
    assert.strictEqual(layout.lead.length + layout.peers.length, 0,
      'non-horizontal states cannot retain horizontal Repeater delegates')
  }
}

const widthTransitions = [0, 359, 469, 470, 499, 500, 719, 720, 721, 900]
const allOrders = permutations(definitions)
for (let mask = 0; mask < (1 << definitions.length); ++mask) {
  const visibleIds = definitions
    .filter((card, index) => (mask & (1 << index)) !== 0)
    .map(card => card.id)
  for (const order of allOrders) {
    const orderIds = order.map(card => card.id)
    const ordered = cards.orderedVisible(orderIds, visibleIds)
    for (const mode of ['auto', 'one', 'two']) {
      for (const width of widthTransitions) {
        const layout = cards.resolveDashboardLayout(ordered, mode, width, {}, 10)
        assertLayoutState(layout, ordered, mode, width)
      }
    }
  }
}

// Exhaustively audit every visible 3-, 4- and 5-card set, configured order,
// and compact/expanded size combination. This specifically covers the
// mixed-height lower Bento columns that are easiest to regress visually.
const geometryGap = cards.COLUMN_GAP
assert.strictEqual(geometryGap, 6, 'the shared Bento geometry uses the established six-pixel card gutter')
function minimumStackDifference(source, sizes, gap) {
  if (source.length === 0) return 0
  if (source.length === 1) return cards.cardHeight(source[0].id, sizes)
  let best = Infinity
  const limit = 1 << source.length
  for (let mask = 1; mask < limit - 1; ++mask) {
    if ((mask & 1) === 0) continue
    const left = []
    const right = []
    source.forEach((card, index) => ((mask & (1 << index)) ? left : right).push(card))
    best = Math.min(best, Math.abs(
      cards.stackHeight(left, sizes, gap) - cards.stackHeight(right, sizes, gap)
    ))
  }
  return best
}
function assertOrderedSubset(column, source, description) {
  const sourcePositions = column.map(card => source.findIndex(item => item.id === card.id))
  assert.ok(sourcePositions.every((position, index) => position >= 0
    && (index === 0 || position > sourcePositions[index - 1])), description)
}
let exhaustiveCombinationCount = 0
for (let visibleMask = 0; visibleMask < (1 << allDefinitions.length); ++visibleMask) {
  const visible = allDefinitions.filter((card, index) => (visibleMask & (1 << index)) !== 0)
  if (visible.length === 0) continue
  for (const ordered of permutations(visible)) {
    for (let sizeMask = 0; sizeMask < (1 << ordered.length); ++sizeMask) {
      const sizes = {}
      ordered.forEach((card, index) => {
        sizes[card.id] = (sizeMask & (1 << index)) ? 'expanded' : 'compact'
      })
      const wide = cards.resolveDashboardLayout(ordered, 'two', 900, sizes, geometryGap)
      assertLayoutState(wide, ordered, 'two', 900)
      if (ordered.length >= 3) {
        const peers = wide.peers
        const peerColumns = cards.wideLeadPeerColumns(peers, sizes, geometryGap)
        assert.ok(peerColumns.left.length > 0 && peerColumns.right.length > 0,
          'wide Bento keeps both peer columns populated for every size combination')
        assertOrderedSubset(peerColumns.left, peers, 'left peer column preserves configured order')
        assertOrderedSubset(peerColumns.right, peers, 'right peer column preserves configured order')
        const peerIds = peerColumns.left.concat(peerColumns.right).map(card => card.id)
        assert.strictEqual(new Set(peerIds).size, peers.length,
          'wide Bento has no duplicated peer card across its lower columns')
        assert.deepStrictEqual(Array.from(peerIds).sort(), Array.from(peers, card => card.id).sort(),
          'wide Bento retains every peer card across its lower columns')
        const leftHeight = cards.stackHeight(peerColumns.left, sizes, geometryGap)
        const rightHeight = cards.stackHeight(peerColumns.right, sizes, geometryGap)
        assert.strictEqual(Math.abs(leftHeight - rightHeight), minimumStackDifference(peers, sizes, geometryGap),
          'wide Bento chooses the most balanced peer-column partition for every size combination')
        assert.strictEqual(cards.wideLeadHorizontalHeight(ordered, sizes, geometryGap),
          cards.cardHeight(ordered[0].id, sizes) + geometryGap + Math.max(leftHeight, rightHeight),
          'wide Bento scroll height follows the lead and naturally sized peer columns without stretching')
      } else if (ordered.length === 2) {
        assertOrderedSubset(wide.left, ordered, 'two-card wide layout preserves left-column order')
        assertOrderedSubset(wide.right, ordered, 'two-card wide layout preserves right-column order')
        assert.ok(wide.left.length > 0 && wide.right.length > 0,
          'two visible cards occupy separate columns without stretching')
        assert.strictEqual(Math.abs(
          cards.stackHeight(wide.left, sizes, geometryGap)
          - cards.stackHeight(wide.right, sizes, geometryGap)
        ), minimumStackDifference(ordered, sizes, geometryGap),
        'two-card wide layout preserves each selected card height')
      } else {
        assert.strictEqual(wide.kind, 'single', 'one visible card remains a single natural-height card')
        assert.deepStrictEqual(Array.from(wide.left, card => card.id), [ordered[0].id])
        assert.strictEqual(wide.right.length, 0)
      }
      ordered.forEach(card => {
        assert.strictEqual(cards.cardHeight(card.id, sizes), sizes[card.id] === 'expanded' ? 208 : 164,
          'each card keeps its own compact or expanded silhouette')
      })

      const narrowTwoColumn = cards.resolveDashboardLayout(ordered, 'two', 499, sizes, geometryGap)
      assertLayoutState(narrowTwoColumn, ordered, 'two', 499)
      if (ordered.length === 3) {
        assert.strictEqual(cards.stackHeight(narrowTwoColumn.right, sizes, geometryGap),
          cards.cardHeight(narrowTwoColumn.right[0].id, sizes)
            + geometryGap + cards.cardHeight(narrowTwoColumn.right[1].id, sizes),
          'three-card narrow Bento spanning card tracks exactly the two naturally sized right cards')
      } else if (ordered.length > 1) {
        assertOrderedSubset(narrowTwoColumn.left, ordered, 'narrow left column preserves configured order')
        assertOrderedSubset(narrowTwoColumn.right, ordered, 'narrow right column preserves configured order')
        if (ordered.length > 2)
          assert.ok(narrowTwoColumn.left.length > 0 && narrowTwoColumn.right.length > 0,
            'narrow balanced layout keeps both columns populated')
        const narrowDifference = Math.abs(
          cards.stackHeight(narrowTwoColumn.left, sizes, geometryGap)
          - cards.stackHeight(narrowTwoColumn.right, sizes, geometryGap)
        )
        assert.strictEqual(narrowDifference, minimumStackDifference(ordered, sizes, geometryGap),
          'narrow balanced columns choose the optimal partition for every size combination')
      } else {
        assert.strictEqual(narrowTwoColumn.kind, 'single',
          'one visible card remains a single card in explicit two-column mode')
      }
      const autoNarrow = cards.resolveDashboardLayout(ordered, 'auto', 499, sizes, geometryGap)
      assert.strictEqual(autoNarrow.kind, 'single',
        'auto mode consistently keeps a one-column layout below the responsive breakpoint')
      exhaustiveCombinationCount++
    }
  }
}
assert.strictEqual(exhaustiveCombinationCount, 6330,
  'the audit covers all configured orders and size combinations for every visible set of 1–5 cards')

// Simulate the settings changing while Dashboard remains open: four cards ->
// three -> two -> three with a new lead -> reordered three -> four again.
// Include Today so this is a genuine custom four-card selection, not the legacy
// all-four-module default that the migration intentionally upgrades.
let liveVisible = ['today', 'network', 'weather', 'media']
let liveOrder = cards.normalizeOrder(['network', 'today', 'weather', 'media'])
function liveLayout(width = 900, mode = 'auto') {
  const ordered = cards.orderedVisible(liveOrder, liveVisible)
  return { ordered, layout: cards.resolveDashboardLayout(ordered, mode, width, {}, 10) }
}
let live = liveLayout()
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 'four enabled cards begin with the first configured card spanning the top row')
liveVisible = cards.setEnabled(liveVisible, 'media', false)
live = liveLayout()
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 'disabling one card switches to the horizontal three-card Bento')
assert.strictEqual(live.layout.lead[0].id, 'network', 'the leading card is selected from the currently visible configured order')
liveVisible = cards.setEnabled(liveVisible, 'network', false)
live = liveLayout()
assert.strictEqual(live.layout.kind, 'balanced', 'disabling another card returns to the two-card layout')
liveVisible = cards.setEnabled(liveVisible, 'network', true)
live = liveLayout()
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 're-enabling a card restores the three-card Bento')
assert.strictEqual(live.layout.lead[0].id, 'network', 're-enabled cards re-enter at their configured order position')
liveOrder = cards.move(liveOrder, 'network', 1)
live = liveLayout()
assert.strictEqual(live.layout.lead[0].id, 'today', 'reordering the visible cards immediately changes the Bento lead')
assert.deepStrictEqual(Array.from(live.layout.peers, card => card.id), ['network', 'weather'],
  'reordering also updates both peer positions without duplication')
live = liveLayout(499, 'auto')
assert.strictEqual(live.layout.kind, 'single', 'auto mode falls back to one column immediately below the 500px threshold')
live = liveLayout(500, 'auto')
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 'auto mode uses horizontal Bento as soon as its two-column threshold is reached')
live = liveLayout(499, 'two')
assert.strictEqual(live.layout.kind, 'three-vertical', 'explicit two-column mode retains vertical Bento below 500px')
live = liveLayout(500, 'two')
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 'crossing 500px switches the current three-card set to horizontal Bento')
assert.strictEqual(live.layout.left.length + live.layout.right.length, 0,
  'crossing into horizontal Bento clears vertical models in the same resolved state')
live = liveLayout(499, 'two')
assert.strictEqual(live.layout.kind, 'three-vertical', 'shrinking below 500px restores vertical Bento without stale horizontal models')
live = liveLayout(470, 'two')
assert.strictEqual(live.layout.kind, 'three-vertical', 'explicit two-column mode permits vertical Bento at its 470px minimum')
live = liveLayout(469, 'two')
assert.strictEqual(live.layout.kind, 'single', 'explicit two-column mode returns to one column below 470px')
live = liveLayout(900, 'one')
assert.strictEqual(live.layout.kind, 'single', 'explicit one-column mode never enables Bento on a wide window')
liveVisible = cards.setEnabled(liveVisible, 'media', true)
live = liveLayout()
assert.strictEqual(live.layout.kind, 'wide-lead-horizontal', 'enabling the fourth card preserves the full-width configured lead')
assert.strictEqual(assignedIds(live.layout).length, 4, 'the final four-card state contains every card once')

for (let mask = 0; mask < (1 << definitions.length); ++mask) {
  const sizes = {};
  definitions.forEach((card, index) => { sizes[card.id] = (mask & (1 << index)) ? 'expanded' : 'compact'; });
  const split = cards.balancedColumns(definitions, sizes, 10);
  const leftIds = Array.from(split.left, card => card.id);
  const rightIds = Array.from(split.right, card => card.id);
  const combined = leftIds.concat(rightIds).sort();
  assert.deepStrictEqual(combined, ['media', 'network', 'system', 'weather'], 'every size combination keeps all cards exactly once');
  assert.ok(split.left.length > 0 && split.right.length > 0, 'four visible module cards always occupy both columns');
  const leftOrder = leftIds.map(id => definitions.findIndex(card => card.id === id));
  const rightOrder = rightIds.map(id => definitions.findIndex(card => card.id === id));
  assert.ok(leftOrder.every((value, index) => index === 0 || value > leftOrder[index - 1]), 'left column preserves configured order');
  assert.ok(rightOrder.every((value, index) => index === 0 || value > rightOrder[index - 1]), 'right column preserves configured order');
  const difference = Math.abs(heightOf(split.left, sizes) - heightOf(split.right, sizes));
  assert.ok(difference <= Math.max(...definitions.map(card => cards.cardHeight(card.id, sizes))) + 10, 'balanced column difference stays bounded for all size combinations');
}

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const page = read('components/settings/sections/SettingsDashboardSection.qml');
const dashboard = read('components/Dashboard.qml');
const settings = read('Settings.qml');
assert.match(dashboard, /targetWidth: DashboardCards\.drawerWidthForScreenWidth\(parent\.width\)/,
  'Dashboard drawer width depends only on the screen and never expands for wide-lead Bento');
assert.match(config, /property var dashboardCardSizes: \(\{ today: "compact", system: "compact", network: "compact", weather: "compact", media: "compact" \}\)/);
assert.match(defaults, /dashboardCardSizes: \(\{ today: "compact", system: "compact", network: "compact", weather: "compact", media: "compact" \}\)/);
assert.match(page, /model: \["Компактный", "Расширенный"\]/);
assert.match(page, /Расширенный размер показывает дополнительные данные модуля/,
  'settings explain that expanded cards reveal additional module details');
assert.match(page, /settingsSearchId: "dashboard-card-size-" \+ cardSettings\.cardId/);
assert.match(page, /root\.setCardSize\(cardSettings\.cardId, DashboardCards\.CARD_SIZE_MODES\[index\]\)/);
assert.match(page, /DashboardCards\.setCardSize\(Config\.dashboardCardSizes, id, mode\)/);
assert.match(dashboard, /DashboardCards\.cardHeight\(modelData\.id, Config\.dashboardCardSizes\)/,
  'each InfoCard receives its own selected height');
assert.ok(dashboard.includes('property string navigationCardId: ""'),
  'Dashboard stores the currently focused module card by stable logical id');
assert.ok(dashboard.includes('navigationCardId = target.navigationCard ? String(target.cardId || "") : ""'),
  'focus tracking records a card id rather than depending only on a delegate Item reference');
assert.ok(dashboard.includes('DashboardCards.clampScrollPosition(')
  && dashboard.includes('!isFinite(cardsFlickable.contentY)')
  && dashboard.includes('cardsFlickable.contentY = boundedY'),
  'contentY is clamped when responsive content shrinks');
assert.ok(dashboard.includes('onContentHeightChanged: root.scheduleDashboardLayoutSync()')
  && dashboard.includes('onHeightChanged: root.scheduleDashboardLayoutSync()'),
  'content and viewport changes schedule a post-layout scroll/focus synchronization');
assert.ok(dashboard.includes('function restoreNavigationCardFocus()')
  && dashboard.includes('dashboardHasOrderedCard(wanted)')
  && dashboard.includes('String(target.cardId || "") === wanted'),
  'keyboard focus is restored to the same visible module after delegate rebuilds');
assert.ok(dashboard.includes('navigationCardId = cardId')
  && dashboard.includes('scheduleDashboardLayoutSync()'),
  'delegate destruction retains logical focus when the module remains in the ordered visible set');
assert.match(dashboard, /readonly property var layoutState: DashboardCards\.resolveDashboardLayout\([\s\S]*?orderedCards, Config\.dashboardColumnsMode, width,[\s\S]*?Config\.dashboardCardSizes, DashboardCards\.COLUMN_GAP[\s\S]*?property bool useTwoColumns: layoutState\.columns === 2[\s\S]*?property bool useWideLeadHorizontalLayout: layoutState\.kind === "wide-lead-horizontal"/,
  'one resolved state recomputes the layout from width, column mode and the current ordered visible cards');
assert.match(dashboard, /property var horizontalLeadCards: layoutState\.lead[\s\S]*?property var horizontalPeerCards: layoutState\.peers[\s\S]*?property var columnSplit: \(\{ left: layoutState\.left, right: layoutState\.right \}\)/,
  'horizontal and vertical Repeater models come from mutually exclusive resolver outputs');
assert.match(dashboard, /id: horizontalBentoLayout[\s\S]*?visible: cards\.useWideLeadHorizontalLayout[\s\S]*?model: cards\.horizontalLeadCards[\s\S]*?wideLead: true/,
  'wide Bento places the first configured card above two balanced peer columns');
assert.match(dashboard, /horizontalBentoRowHeight: useWideLeadHorizontalLayout[\s\S]*?DashboardCards\.threeCardHorizontalRowHeight\(orderedCards, Config\.dashboardCardSizes\)[\s\S]*?horizontalPeerRowHeight: useWideLeadHorizontalLayout[\s\S]*?DashboardCards\.stackHeight\(/,
  'wide Bento derives the lead and lower-peer rows from their own natural card sizes');
assert.match(dashboard, /delegate: Item \{[\s\S]*?id: horizontalLeadSlot[\s\S]*?Layout\.preferredHeight: cards\.horizontalBentoRowHeight[\s\S]*?InfoCard \{[\s\S]*?anchors\.centerIn: parent[\s\S]*?height: DashboardCards\.cardHeight\(horizontalLeadSlot\.modelData\.id, Config\.dashboardCardSizes\)/,
  'the leading card uses a row track matching its own selected silhouette');
assert.match(dashboard, /id: horizontalBentoLayout[\s\S]*?RowLayout \{[\s\S]*?Layout\.preferredHeight: cards\.horizontalPeerRowHeight[\s\S]*?model: \[cards\.horizontalPeerColumns\.left, cards\.horizontalPeerColumns\.right\][\s\S]*?Layout\.alignment: Qt\.AlignTop[\s\S]*?model: horizontalPeerColumnSlot\.modelData[\s\S]*?Layout\.preferredHeight: DashboardCards\.cardHeight\(modelData\.id, Config\.dashboardCardSizes\)/,
  'lower peer columns keep independent card heights and top-align shorter compact stacks');
assert.match(dashboard, /id: cardColumns[\s\S]*?visible: cards\.orderedCards\.length > 0 && !cards\.useWideLeadHorizontalLayout[\s\S]*?model: cards\.columnSplit\.left[\s\S]*?model: cards\.columnSplit\.right/,
  'vertical Bento, narrow multi-card balanced stacks, and one-column layout keep their existing column renderer');
assert.match(dashboard, /DashboardCards\.wideLeadHorizontalHeight\(orderedCards, Config\.dashboardCardSizes, DashboardCards\.COLUMN_GAP\)/,
  'wide Bento scroll height accounts for its top card and the taller complete peer stack');
assert.match(dashboard, /DashboardCards\.stackHeight\(columnSplit\.right, Config\.dashboardCardSizes, DashboardCards\.COLUMN_GAP\)/,
  'the spanning card height matches the two stacked cards and their gutter');
assert.match(dashboard, /useWideLeadHorizontalLayout[\s\S]*?DashboardCards\.wideLeadHorizontalHeight[\s\S]*?Math\.max\(leftColumn\.implicitHeight, useTwoColumns \? rightColumn\.implicitHeight : 0\)/,
  'scroll content height follows the horizontal Bento rows or the taller complete column');
assert.match(dashboard, /Keep each card's content block on a shared vertical centreline[\s\S]*?Item \{[\s\S]*?Layout\.fillHeight: (?:true|!\(infoCard\.cardId === "today" && infoCard\.wideLead\))[\s\S]*?Layout\.minimumHeight: 0[\s\S]*?ColumnLayout \{\s*visible: !infoCard\.expanded[\s\S]*?Item \{[\s\S]*?Layout\.fillHeight: (?:true|!\(infoCard\.cardId === "today" && infoCard\.wideLead\))[\s\S]*?Layout\.minimumHeight: 0[\s\S]*?Rectangle \{\s*Layout\.fillWidth: true\s*height: 1/,
  'other cards retain flexible centering while every wide Today size can collapse the spacers');
assert.match(dashboard, /visible: infoCard\.expanded && infoCard\.cardId === "system"[\s\S]*?UsageMeter[\s\S]*?value: infoCard\.secondaryValue/,
  'expanded system card renders independent CPU and RAM usage meters');
assert.match(dashboard, /visible: infoCard\.expanded && infoCard\.cardId === "network"[\s\S]*?detailPrimaryText[\s\S]*?detailSecondaryText/,
  'expanded network card shows download and upload rates with transferred totals');
assert.match(dashboard, /visible: infoCard\.expanded && infoCard\.cardId === "weather"[\s\S]*?comfortText[\s\S]*?windText/,
  'expanded weather card shows its available icon, feels-like temperature and wind details');
assert.match(dashboard, /visible: infoCard\.expanded && infoCard\.cardId === "media"[\s\S]*?tertiaryText/,
  'expanded media card uses the backend third metadata line when available');
assert.match(dashboard, /tertiaryText: modelData\.id === "media" && Settings\.player \? root\.mediaDetail : ""/,
  'Dashboard passes media third-line metadata into the card');
assert.match(settings, /"dashboardColumnsMode", "dashboardCardSizes"/);

const persistence = load('js/settings/SettingsPersistence.js',
  'this.api = { snapshotObject, normalizeDashboardCardSizes };').api;
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, {
  dashboardCardSizes: { system: 'expanded', media: 'expanded', unexpected: 'expanded' }
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(snapshot.dashboardCardSizes)), {
  today: 'compact', system: 'expanded', network: 'compact', weather: 'compact', media: 'expanded'
}, 'per-card sizes are validated and persisted in the profile snapshot');
assert.deepStrictEqual(JSON.parse(JSON.stringify(persistence.normalizeDashboardCardSizes(null))), {
  today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'compact'
});

const profiles = load('js/settings/SettingsProfiles.js', 'this.api = { profileSavePathMatches };').api;
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboard', null, ['dashboardCardSizes', 'weather']), true,
  'nested per-card size changes belong to Dashboard-scoped profiles');

const apply = load('js/settings/SettingsApplySystemVisual.js', 'this.api = { apply, normalizeDashboardCardSizes };').api;
const applied = {};
apply.apply(applied, { dashboardCardSizes: { network: 'expanded' } });
assert.deepStrictEqual(JSON.parse(JSON.stringify(applied.dashboardCardSizes)), {
  today: 'compact', system: 'compact', network: 'expanded', weather: 'compact', media: 'compact'
}, 'profile application restores size values while filling omissions');
const legacyApplied = { dashboardCardSizes: { system: 'expanded' } };
apply.apply(legacyApplied, {});
assert.deepStrictEqual(JSON.parse(JSON.stringify(legacyApplied.dashboardCardSizes)), {
  today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'compact'
}, 'profiles predating card sizes reset to compact defaults instead of leaking prior profile state');

const resets = load('js/settings/SettingsResets.js', 'this.api = { resetDashboardSettings };').api;
const resetConfig = { dashboardCardSizes: { system: 'expanded', network: 'expanded' } };
let saves = 0;
const owner = {
  activeProfile: 'Default', profiles: { Default: {} },
  expandedProfileData: () => ({ dashboardCardSizes: { weather: 'expanded' } }),
  defaultConfig: { dashboardCardSizes: { system: 'compact', network: 'compact', weather: 'compact', media: 'compact' } },
  save: () => saves++, resetUnavailable: () => {}
};
resets.resetDashboardSettings(owner, resetConfig);
assert.deepStrictEqual(JSON.parse(JSON.stringify(resetConfig.dashboardCardSizes)), {
  today: 'compact', system: 'compact', network: 'compact', weather: 'expanded', media: 'compact'
}, 'reset restores the active profile card sizes independently');
assert.strictEqual(saves, 1);
owner.expandedProfileData = () => ({});
resets.resetDashboardSettings(owner, resetConfig);
assert.deepStrictEqual(JSON.parse(JSON.stringify(resetConfig.dashboardCardSizes)), {
  today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'compact'
}, 'legacy profiles reset card sizes to compact defaults');

console.log('Dashboard per-card compact/expanded sizes, rendering, persistence, profiles and reset: OK');
NODE
