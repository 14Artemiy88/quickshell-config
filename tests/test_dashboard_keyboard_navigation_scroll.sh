#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/Dashboard.qml" "$ROOT/js/dashboard/DashboardCards.js" <<'PY'
from pathlib import Path
import sys

qml = Path(sys.argv[1]).read_text()
cards = Path(sys.argv[2]).read_text()

# The full drawer receives spatial keys before the focused child. Tab navigation
# remains native Qt Quick tab order for the same actionable controls.
assert 'Keys.priority: Keys.BeforeItem' in qml
for key in ('Qt.Key_Left', 'Qt.Key_Right', 'Qt.Key_Up', 'Qt.Key_Down'):
    assert key in qml[qml.index('Keys.onPressed: function(event)', qml.index('id: drawer')):qml.index('Behavior on x', qml.index('id: drawer'))]
assert 'root.moveKeyboardFocus(event.key)' in qml
assert 'root.moveKeyboardPage(event.key)' in qml
assert 'root.moveKeyboardToEdge(event.key)' in qml
assert 'activeFocusOnTab: enabled' in qml, 'cards and quick actions must remain reachable by Tab'
assert 'activeFocusOnTab: true' in qml, 'the close action must remain reachable by Tab'
assert 'Accessible.role: Accessible.Button' in qml
assert 'Accessible.name: infoCard.title' in qml
assert 'Accessible.description: infoCard.accessibleDetails()' in qml
assert 'event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space' in qml
assert 'root.clearNavigationFocus()' in qml, 'closing Dashboard must clear stale keyboard selection'
assert 'navigationCardId = target.navigationCard ? String(target.cardId || "") : ""' in qml
assert 'function restoreNavigationCardFocus()' in qml and 'root.restoreNavigationCardFocus()' in qml
assert 'var top = position.y' in qml and 'var bottom = top + target.height' in qml
assert 'cardsFlickable.contentY = Math.max(0, top)' in qml
assert 'cardsFlickable.contentY = Math.max(0, bottom - cardsFlickable.height)' in qml
assert 'ScrollBar.vertical:' not in qml, 'Dashboard scrollbar must remain hidden'
assert 'clip: true' in qml
assert 'boundsBehavior: Flickable.StopAtBounds' in qml
assert 'acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad' in qml
assert 'DashboardCards.wheelScrollPosition(' in qml
assert 'event.accepted = true' in qml
assert 'function wheelScrollPosition(position, contentHeight, viewportHeight, pixelDeltaY, angleDeltaY)' in cards
assert 'return clampScrollPosition(' in cards[cards.index('function wheelScrollPosition'):cards.index('function normalizeColumnsMode')]
print('Dashboard keyboard/focus/scroll contract: PASS')
PY

node - "$ROOT/components/Dashboard.qml" "$ROOT/js/dashboard/DashboardCards.js" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [qmlPath, cardsPath] = process.argv.slice(2);
const qml = fs.readFileSync(qmlPath, 'utf8');
const cardsSource = fs.readFileSync(cardsPath, 'utf8');

function extractFunction(source, name) {
  const marker = `function ${name}(`;
  const start = source.indexOf(marker);
  assert(start >= 0, `missing function ${name}`);
  const brace = source.indexOf('{', start);
  assert(brace >= 0, `missing body for ${name}`);
  let depth = 0;
  let state = 'code';
  let escaped = false;
  for (let i = brace; i < source.length; i++) {
    const ch = source[i];
    const next = source[i + 1];
    if (state === 'line') {
      if (ch === '\n') state = 'code';
      continue;
    }
    if (state === 'block') {
      if (ch === '*' && next === '/') { state = 'code'; i++; }
      continue;
    }
    if (state === 'single' || state === 'double' || state === 'template') {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if ((state === 'single' && ch === "'")
          || (state === 'double' && ch === '"')
          || (state === 'template' && ch === '`')) state = 'code';
      continue;
    }
    if (ch === '/' && next === '/') { state = 'line'; i++; continue; }
    if (ch === '/' && next === '*') { state = 'block'; i++; continue; }
    if (ch === "'") { state = 'single'; continue; }
    if (ch === '"') { state = 'double'; continue; }
    if (ch === '`') { state = 'template'; continue; }
    if (ch === '{') depth++;
    if (ch === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unclosed function ${name}`);
}

function compileMethod(source, name, bindings) {
  const params = Object.keys(bindings);
  const values = Object.values(bindings);
  return new Function(...params, `${source}\nreturn ${name};`)(...values);
}

const Qt = {
  Key_Left: 1, Key_Right: 2, Key_Up: 3, Key_Down: 4,
  Key_PageUp: 5, Key_PageDown: 6, Key_Home: 7, Key_End: 8
};
const clamp = compileMethod(extractFunction(cardsSource, 'clampScrollPosition'), 'clampScrollPosition', {});
const wheel = compileMethod(extractFunction(cardsSource, 'wheelScrollPosition'), 'wheelScrollPosition', { clampScrollPosition: clamp });
assert.strictEqual(wheel(100, 1000, 400, -32, 0), 132, 'touchpad pixel delta moves the content by its exact pixel amount');
assert.strictEqual(wheel(100, 1000, 400, 0, -120), 164, 'one downward mouse-wheel notch uses the 64 px fallback');
assert.strictEqual(wheel(100, 1000, 400, 32, 120), 68, 'pixel delta takes precedence when both delta forms are present');
assert.strictEqual(wheel(0, 1000, 400, 0, 120), 0, 'upward wheel input is clamped at the top');
assert.strictEqual(wheel(600, 1000, 400, 0, -120), 600, 'downward wheel input is clamped at the bottom');
assert.strictEqual(wheel(100, 300, 400, 0, -120), 0, 'non-scrollable content stays at the top');
assert.strictEqual(wheel(100, 1000, 400, NaN, -120), 164, 'invalid pixel deltas safely fall back to angle delta');
assert.strictEqual(wheel(100, 1000, 400, 0, 0), null, 'zero vertical movement is left unhandled');
assert.strictEqual(wheel(NaN, 1000, 400, 0, -120), 64, 'invalid starting offsets recover from the top');

const score = compileMethod(extractFunction(qml, 'directionalNavigationScore'), 'directionalNavigationScore', { Qt });
const center = { left: 100, top: 100, right: 200, bottom: 150, centerX: 150, centerY: 125 };
const rightAligned = { left: 220, top: 105, right: 320, bottom: 155, centerX: 270, centerY: 130 };
const rightDiagonal = { left: 205, top: 320, right: 305, bottom: 370, centerX: 255, centerY: 345 };
assert(Number.isFinite(score(center, rightAligned, Qt.Key_Right)), 'a right-side target is eligible');
assert(score(center, rightAligned, Qt.Key_Right) < score(center, rightDiagonal, Qt.Key_Right), 'same-row targets win over distant diagonal targets');
assert.strictEqual(score(center, rightAligned, Qt.Key_Left), Infinity, 'targets behind the requested direction are excluded');
assert.strictEqual(score(center, rightAligned, Qt.Key_Down), Infinity, 'overlapping targets are not treated as below');

const rootForNavigation = {
  navigationRect: target => target.rect,
  navigationTargetUsable: target => !!(target && target.enabled !== false && target.visible !== false && target.width > 0 && target.height > 0)
};
const entry = compileMethod(extractFunction(qml, 'navigationEntryCompare'), 'navigationEntryCompare', { root: rootForNavigation, Qt, navigationRect: rootForNavigation.navigationRect });
rootForNavigation.navigationEntryCompare = entry;
const left = { width: 100, height: 40, enabled: true, visible: true, rect: { left: 0, top: 100, right: 100, bottom: 140, centerX: 50, centerY: 120 } };
const middle = { width: 100, height: 40, enabled: true, visible: true, rect: { left: 120, top: 100, right: 220, bottom: 140, centerX: 170, centerY: 120 } };
const current = { width: 100, height: 40, enabled: true, visible: true, rect: { left: 240, top: 100, right: 340, bottom: 140, centerX: 290, centerY: 120 } };
const otherRow = { width: 100, height: 40, enabled: true, visible: true, rect: { left: 0, top: 240, right: 100, bottom: 280, centerX: 50, centerY: 260 } };
const wrap = compileMethod(extractFunction(qml, 'wrappedNavigationTarget'), 'wrappedNavigationTarget', { root: rootForNavigation, Qt, navigationRect: rootForNavigation.navigationRect, navigationTargetUsable: rootForNavigation.navigationTargetUsable });
assert.strictEqual(wrap(current, [left, middle, otherRow], Qt.Key_Right, null), left, 'horizontal wrap stays on the same row and returns to its opposite edge');

// Initial arrow entry and normal movement are exercised against the extracted
// production function, with item geometry represented in drawer coordinates.
const focusLog = [];
const root = {
  navigationTargetUsable: rootForNavigation.navigationTargetUsable,
  navigationRect: target => target.rect,
  navigationEntryCompare: entry,
  nearestNavigationTarget: () => null
};
const focus = target => focusLog.push(target);
function makeFocusFunction(currentTarget, candidates, started = false) {
  return compileMethod(extractFunction(qml, 'moveKeyboardFocus'), 'moveKeyboardFocus', {
    navigationTargets: candidates,
    currentNavigationTarget: currentTarget,
    lastNavigationTarget: currentTarget,
    navigationStarted: started,
    hasNavigationAnchor: false,
    navigationAnchor: { x: 0, y: 0 },
    root,
    Qt,
    navigationRect: root.navigationRect,
    directionalNavigationScore: score,
    focusNavigationTarget: focus,
    wrappedNavigationTarget: wrap,
    navigationTargetUsable: root.navigationTargetUsable
  });
}
focusLog.length = 0;
makeFocusFunction(null, [current, middle, left])(Qt.Key_Right);
assert.strictEqual(focusLog.at(-1), left, 'the first Right press enters from the left edge');
const below = { width: 100, height: 40, enabled: true, visible: true, rect: { left: 240, top: 180, right: 340, bottom: 220, centerX: 290, centerY: 200 } };
focusLog.length = 0;
makeFocusFunction(current, [current, below], true)(Qt.Key_Down);
assert.strictEqual(focusLog.at(-1), below, 'vertical navigation follows the current card column');

// Page movement scrolls by nearly one viewport with overlap and then focuses
// the card nearest the newly exposed edge, using the production method.
const flickable = {
  contentY: 0, contentHeight: 1500, height: 400,
  mapToItem: () => ({ x: 0, y: 100 })
};
const cards = [0, 300, 650, 1000, 1300].map((top, index) => ({
  navigationCard: true, cardId: `card-${index}`, enabled: true, visible: true,
  width: 120, height: 50, contentTop: top
}));
let focused = null;
const scrollRoot = {
  navigationRect: target => ({
    left: 20, right: 140, centerX: 80,
    top: 100 + target.contentTop - flickable.contentY,
    bottom: 150 + target.contentTop - flickable.contentY,
    centerY: 125 + target.contentTop - flickable.contentY
  }),
  navigationTargetUsable: rootForNavigation.navigationTargetUsable,
  focusNavigationTarget: target => { focused = target; }
};
const page = compileMethod(extractFunction(qml, 'moveKeyboardPage'), 'moveKeyboardPage', {
  cardsFlickable: flickable,
  currentNavigationTarget: cards[0],
  drawer: {},
  navigationTargets: cards,
  navigationRect: scrollRoot.navigationRect,
  navigationTargetUsable: scrollRoot.navigationTargetUsable,
  focusNavigationTarget: scrollRoot.focusNavigationTarget,
  root: scrollRoot
});
page(Qt.Key_PageDown);
assert.strictEqual(flickable.contentY, 352, 'PageDown advances by one viewport minus a 48 px overlap');
assert.strictEqual(focused, cards[2], 'PageDown focuses a visible card near the new viewport top');
page(Qt.Key_PageUp);
assert.strictEqual(flickable.contentY, 0, 'PageUp clamps to the start');
assert.strictEqual(focused, cards[1], 'PageUp focuses the card nearest the new viewport bottom');
flickable.contentY = 1100;
focused = null;
page(Qt.Key_PageDown);
assert.strictEqual(flickable.contentY, 1100, 'PageDown clamps at the final scroll offset');
assert.strictEqual(focused, null, 'a page key at the boundary does not jump focus unexpectedly');

// Arrow navigation and direct focus restoration keep the selected card fully
// inside the Flickable viewport, even when its target is above or below it.
const focusFlickable = {
  contentY: 100, height: 300,
  contentItem: {},
};
let forceFocused = false;
let focusState = null;
const focusIntoView = compileMethod(extractFunction(qml, 'focusNavigationTarget'), 'focusNavigationTarget', {
  navigationTargetUsable: rootForNavigation.navigationTargetUsable,
  setNavigationTargetFocused: target => { focusState = target; },
  cardsFlickable: focusFlickable
});
const visibleCard = {
  enabled: true, visible: true, width: 100, height: 80, navigationCard: true,
  mapToItem: () => ({ x: 0, y: 150 }),
  forceActiveFocus: () => { forceFocused = true; }
};
focusIntoView(visibleCard);
assert.strictEqual(focusFlickable.contentY, 100, 'already visible card does not disturb scroll position');
assert.strictEqual(forceFocused, true, 'the destination receives native keyboard focus');
assert.strictEqual(focusState, visibleCard, 'logical focus state follows the selected target');
const aboveCard = { ...visibleCard, mapToItem: () => ({ x: 0, y: 20 }) };
focusIntoView(aboveCard);
assert.strictEqual(focusFlickable.contentY, 20, 'card above the viewport scrolls to its top edge');
const belowCard = { ...visibleCard, mapToItem: () => ({ x: 0, y: 480 }) };
focusIntoView(belowCard);
assert.strictEqual(focusFlickable.contentY, 260, 'card below the viewport scrolls so its bottom edge is visible');

// Home/End follow configured order, not the card's visual column order.
const edgeFlickable = { contentY: 350, contentHeight: 1000, height: 300 };
const orderedCards = [{ id: 'media' }, { id: 'today' }, { id: 'system' }];
const edgeTargets = ['today', 'system', 'media'].map(id => ({
  navigationCard: true, cardId: id, enabled: true, visible: true, width: 100, height: 40
}));
const edgeFocus = [];
const edgeRoot = {
  navigationTargetUsable: rootForNavigation.navigationTargetUsable,
  focusNavigationTarget: target => edgeFocus.push(target)
};
const toEdge = compileMethod(extractFunction(qml, 'moveKeyboardToEdge'), 'moveKeyboardToEdge', {
  cardsFlickable: edgeFlickable,
  cards: { orderedCards },
  navigationTargets: edgeTargets,
  Qt,
  root: edgeRoot
});
toEdge(Qt.Key_Home);
assert.strictEqual(edgeFlickable.contentY, 0, 'Home scrolls to the beginning');
assert.strictEqual(edgeFocus.at(-1).cardId, 'media', 'Home focuses the first configured card');
toEdge(Qt.Key_End);
assert.strictEqual(edgeFlickable.contentY, 700, 'End scrolls to the maximum offset');
assert.strictEqual(edgeFocus.at(-1).cardId, 'system', 'End focuses the last configured card');

console.log('Dashboard keyboard navigation and bounded scroll behavior: PASS');
NODE

echo 'dashboard keyboard navigation and scroll: OK'
