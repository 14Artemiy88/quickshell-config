#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const source = read('js/dashboard/DashboardCards.js')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/mg, '');
const cards = {};
vm.createContext(cards);
vm.runInContext(source, cards, { filename: 'DashboardCards.js' });

const initial = ['today', 'system', 'network', 'weather', 'media'];
assert.deepStrictEqual(Array.from(cards.moveBefore(initial, 'media', 'today')),
  ['media', 'today', 'system', 'network', 'weather'],
  'the legacy moveBefore helper retains its explicit before-target behavior');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'today', 'weather')),
  ['system', 'network', 'weather', 'today', 'media'],
  'dropping an earlier card onto a later card moves it after the target');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'media', 'today')),
  ['media', 'today', 'system', 'network', 'weather'],
  'dropping a later card onto an earlier card moves it before the target');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'today', 'system')),
  ['system', 'today', 'network', 'weather', 'media'],
  'a forward drop onto the adjacent card is no longer a no-op');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'system', 'today')),
  ['system', 'today', 'network', 'weather', 'media'],
  'a backward adjacent drop reorders symmetrically');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'network', 'network')), initial,
  'dropping a card onto itself is a no-op');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'unknown', 'network')), initial,
  'unknown source IDs are rejected');
assert.deepStrictEqual(Array.from(cards.moveByDrop(initial, 'media', 'unknown')), initial,
  'unknown target IDs are rejected');
assert.deepStrictEqual(Array.from(cards.moveByDrop(['weather', 'media'], 'media', 'weather')),
  ['media', 'weather', 'today', 'system', 'network'],
  'moveByDrop normalizes incomplete legacy order data before moving');

const targetRect = { left: 200, right: 400, top: 100, bottom: 260 };
assert.strictEqual(cards.cardDropTargetScore({ x: 300, y: 180 }, targetRect, 88, 72), 0,
  'any point inside a card, not only its centre, is accepted');
assert.strictEqual(cards.cardDropTargetScore({ x: 205, y: 105 }, targetRect, 88, 72), 0,
  'the card corners remain valid drop targets');
assert.strictEqual(cards.cardDropTargetScore({ x: 415, y: 180 }, targetRect, 88, 72), 225,
  'points in the horizontal gap choose the nearest card by rectangle distance');
assert.strictEqual(cards.cardDropTargetScore({ x: 300, y: 320 }, targetRect, 88, 72), 3600,
  'nearby vertical gaps remain forgiving');
assert(cards.cardDropTargetScore({ x: 488, y: 180 }, targetRect, 88, 72) < Infinity,
  'the horizontal tolerance accepts a release close to the card edge');
assert.strictEqual(cards.cardDropTargetScore({ x: 489, y: 180 }, targetRect, 88, 72), Infinity,
  'the horizontal tolerance remains bounded');
assert.strictEqual(cards.cardDropTargetScore({ x: 300, y: 333 }, targetRect, 88, 72), Infinity,
  'points well below the card cannot become drop targets');

const qml = read('components/Dashboard.qml');
const shell = read('shell.qml');
const header = qml.slice(qml.indexOf('id: cardEditButton'), qml.indexOf('id: closeButton'));
assert(header.includes('root.toggleDashboardCardEditMode()')
  && qml.includes('function toggleDashboardCardEditMode()'),
  'Dashboard header exposes a dedicated card editing toggle with drag-state cleanup');
assert(qml.includes('property bool cardEditMode: false'),
  'card editing is transient and disabled by default');
assert(qml.includes('function beginDashboardCardDrag(cardId, sceneX, sceneY)')
  && qml.includes('function updateDashboardCardDrag(cardId, sceneX, sceneY)')
  && qml.includes('function finishDashboardCardDrag(cardId)'),
  'Dashboard implements a complete scene-coordinate drag lifecycle');
assert(qml.includes('DragHandler {') && qml.includes('centroid.scenePosition.x')
  && qml.includes('centroid.scenePosition.y') && qml.includes('onActiveTranslationChanged:')
  && qml.includes('dashboardDragScenePosition'),
  'drag tracking uses scene pointer coordinates so the tiny handle does not distort horizontal movement');
assert(qml.includes('DashboardCards.moveByDrop(Config.dashboardCardOrder, sourceId, targetId)'),
  'drop targets reorder in either direction using the profile-backed card order');
assert(qml.includes('drawer.mapFromItem(null, root.dashboardDragScenePosition.x, root.dashboardDragScenePosition.y)')
  && qml.includes('DashboardCards.cardDropTargetScore(point, rect, slopX, slopY)'),
  'drop hit testing uses the true pointer position and nearest card rectangle, including gaps');
assert(qml.includes('Config.dashboardCardOrder = next') && qml.includes('Config.dashboardVisibleCards = next')
  && qml.includes('Config.dashboardCardSizes = next'),
  'order, visibility and size changes use the existing Dashboard settings');
assert(qml.includes('root.keyboardNavigationActive && infoCard.activeFocus')
  && !qml.includes('pendingDashboardFocusCardId')
  && !source.includes('adjacentVisibleCardId'),
  'pointer-driven add/remove no longer forces a persistent card selection; keyboard focus styling remains');
assert(qml.includes('pendingDashboardCardRemovalId') && qml.includes('pendingDashboardCardAppearanceId')
  && qml.includes('dashboardCardRemovalTimer') && qml.includes('Behavior on scale {')
  && qml.includes('Behavior on opacity {'),
  'adding fades/scales cards in and removing fades/scales them out before model removal');
assert(qml.includes('Сжать') && qml.includes('Расш.'),
  'each visible card offers a compact/expanded size action in edit mode');
assert(qml.includes('Скрыть карточку ') && qml.includes('Добавить карточку '),
  'edit mode can hide cards and restore previously hidden cards');
assert(qml.includes('Behavior on x {') && qml.includes('Behavior on y {')
  && qml.includes('Config.animationDuration(190, "appearance")'),
  'card positions settle smoothly after a reorder while edit mode is active');
assert(qml.includes('Accessible.role: Accessible.Grouping') && qml.includes('HoverHandler {\n            id: cardHover'),
  'cards stay informational and only expose a passive hover handler outside edit mode');
assert(!qml.includes('settingsPageId') && !qml.includes('infoCard.settingsRequested'),
  'in-panel card editing no longer depends on click-to-settings routes');
assert(qml.includes('root.cardEditMode = false') && qml.includes('root.draggingCardId = ""'),
  'closing Dashboard clears transient editing and drag state');
assert(qml.includes('Accessible.role: Accessible.Button'),
  'new editing actions expose semantic button roles');

const moduleSection = read('components/settings/sections/SettingsModulesSection.qml');
assert(moduleSection.includes('onClicked: host.layoutEditRequested()'),
  'the existing desktop smart editor remains the single entry point');
assert(moduleSection.includes('включая Dashboard'),
  'the Smart Editing description explicitly includes Dashboard');
assert(shell.includes('layoutEditMode: Settings.dashboard && shell.layoutEditMode')
  && shell.includes('layoutEditor: moduleLayoutEditorWindow'),
  'the Dashboard overlay receives the shared ModuleLayoutEditorWindow');
console.log('Dashboard in-panel editing, bidirectional drag/drop, pointer/keyboard focus separation and add/remove animations: OK');
JS
