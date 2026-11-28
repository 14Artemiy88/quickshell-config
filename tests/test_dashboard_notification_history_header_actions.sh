#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const qml = fs.readFileSync(path.join(process.argv[2], 'components/Dashboard.qml'), 'utf8');

function blockBetween(startToken, endToken, from = 0) {
  const start = qml.indexOf(startToken, from);
  const end = qml.indexOf(endToken, start + startToken.length);
  assert(start >= 0 && end > start, `locate ${startToken}..${endToken}`);
  return qml.slice(start, end);
}

const clusterStart = qml.indexOf('id: dashboardHeaderActions');
const clusterEnd = qml.indexOf('\n    Shortcut {', clusterStart);
assert(clusterStart >= 0 && clusterEnd > clusterStart, 'one shared top-right header cluster exists');
const cluster = qml.slice(clusterStart, clusterEnd);
assert(cluster.includes('anchors.top: drawer.top') && cluster.includes('anchors.right: drawer.right'),
  'header actions are anchored directly to the Dashboard drawer corner, not a content RowLayout');
assert(cluster.includes('anchors.topMargin: 18') && cluster.includes('anchors.rightMargin: 18'),
  'header actions use the same inset as the drawer content');
assert(cluster.includes('width: implicitWidth') && cluster.includes('height: 36'),
  'the shared cluster sizes itself to its controls');
assert(cluster.includes('spacing: 4'), 'the three header controls use a tighter 4px gap');
assert(cluster.includes('id: settingsButton') && cluster.includes('id: historyBackButton') && cluster.includes('id: closeButton'),
  'the shared cluster contains Settings, Back and the permanent Close action');
assert(cluster.indexOf('id: settingsButton') < cluster.indexOf('id: historyBackButton')
    && cluster.indexOf('id: historyBackButton') < cluster.indexOf('id: closeButton'),
  'the cluster order is Settings, Back, Close');
assert(!qml.includes('id: historySettingsButton') && !qml.includes('id: historyCloseButton'),
  'there are no duplicate header controls attached to the History content row');

const overview = blockBetween('id: mainDashboardContent', 'id: dashboardHistoryContent');
const history = blockBetween('id: dashboardHistoryContent', 'id: dashboardHeaderActions');
assert(overview.includes('Layout.rightMargin: dashboardHeaderActions.implicitWidth + 10'),
  'overview reserves space for the corner controls so header actions cannot push them out of the corner');
assert(history.includes('Layout.rightMargin: dashboardHeaderActions.implicitWidth + 10'),
  'history reserves space for the same corner controls');
assert(!overview.includes('id: settingsButton') && !overview.includes('id: closeButton'),
  'overview content no longer positions the corner controls in its own header RowLayout');
assert(!history.includes('id: historySettingsButton') && !history.includes('id: historyCloseButton'),
  'history content no longer positions duplicate corner controls in its own header RowLayout');

const gear = blockBetween('id: settingsButton', 'id: historyBackButton', clusterStart);
assert(gear.includes('Layout.preferredWidth: 36') && gear.includes('Layout.preferredHeight: 36'),
  'Settings keeps a 36px interaction target');
assert(gear.includes('font.pixelSize: Config.uiFontSize(16)'), 'Settings cog remains visually reduced');
assert(gear.includes('root.closeRequested()') && gear.includes('root.settingsRequested()'),
  'Settings closes Dashboard and opens general Settings');
assert(gear.includes('border.width: activeFocus ? 2 : 0') && !gear.includes('settingsMouse.containsMouse ? Qt.rgba'),
  'Settings has no hover border or hover background');

const back = blockBetween('id: historyBackButton', 'id: closeButton', clusterStart);
assert(back.includes('visible: root.historyViewActive || animatedSlotWidth > 0.5'),
  'Back arrow remains available while its exit animation completes');
assert(back.includes('Layout.preferredWidth: animatedSlotWidth'), 'Back animates its layout slot');
assert(back.includes('text: "‹"') && back.includes('root.historyViewActive = false'),
  'Back arrow returns to the Dashboard overview');
assert(back.includes('historyClearConfirmationPending = false') && back.includes('historyGroupDeleteConfirmationPending = ""'),
  'Back clears pending history confirmations');
assert(!back.includes('root.closeRequested()'), 'Back does not close Dashboard');
assert(back.includes('Behavior on animatedSlotWidth') && back.includes('Behavior on opacity'),
  'Back slot and icon animate in and out');
assert(back.includes('anchors.verticalCenterOffset: -2'),
  'Back arrow is raised by 2px to align optically with the other header icons');
assert(back.includes('border.width: activeFocus ? 2 : 0') && !back.includes('historyBackMouse.containsMouse ? Qt.rgba'),
  'Back has no hover border or hover background');

const close = cluster.slice(cluster.indexOf('id: closeButton'));
assert(close.includes('text: "×"') && close.includes('root.closeRequested()'),
  'the permanent X closes Dashboard in both overview and history');
assert(close.includes('Layout.preferredWidth: 36') && close.includes('Layout.preferredHeight: 36'),
  'the permanent X keeps a 36px target');
assert(close.includes('border.width: activeFocus ? 2 : 0') && !close.includes('closeMouse.containsMouse ? Qt.rgba'),
  'the permanent X has no hover border or hover background');
assert((qml.match(/id: closeButton/g) || []).length === 1, 'there is only one X button instance for both views');
assert(overview.includes('Behavior on opacity') && history.includes('Behavior on opacity'),
  'overview and history retain their page crossfade transitions');
console.log('Dashboard shared corner Settings/Back/Close cluster and reserved header layout: PASS');
NODE
