#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const assert = require('node:assert/strict');
const rootDir = process.argv[2];
const player = fs.readFileSync(path.join(rootDir, 'components/Player.qml'), 'utf8');
const dashboard = fs.readFileSync(path.join(rootDir, 'components/Dashboard.qml'), 'utf8');
const shell = fs.readFileSync(path.join(rootDir, 'shell.qml'), 'utf8');

function functionBody(source, signature) {
  const start = source.indexOf(signature);
  assert.notEqual(start, -1, `missing function ${signature}`);
  const open = source.indexOf('{', start);
  assert.notEqual(open, -1, `missing function body ${signature}`);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}') {
      depth--;
      if (depth === 0) return source.slice(open + 1, i);
    }
  }
  assert.fail(`unterminated function ${signature}`);
}

for (const required of [
  'property bool dashboardActive: false',
  'property var dashboardPlayers: []',
  'property string dashboardSelectedBackend: ""',
  'property var dashboardSelectedSnapshot: null',
  'property int dashboardSelectedMissingPolls: 0',
  'function setDashboardPlayers(value)',
  'function selectDashboardPlayer(backendValue)',
  'function togglePlaybackForBackend(backendValue)',
  'function seekToPercentForBackend(backendValue, percent, durationValue)',
  '"--all", "--priority"',
  'root.dashboardActive && Settings.player',
  'root.setDashboardPlayers(JSON.parse(this.text))'
]) assert(player.includes(required), `Player source selection includes ${required}`);

assert(shell.includes('dashboardActive: Settings.dashboard && shell.dashboardVisible'),
  'all-source polling is enabled only while Dashboard is open');
assert(dashboard.includes('function mediaBackendLabelFor(backendValue)'),
  'source options use readable backend labels');
assert(dashboard.includes('readonly property var mediaAlternativePlayers'),
  'Dashboard derives alternatives independently from the current source');
assert(dashboard.includes('backend !== activeBackend'),
  'the active player is excluded from alternative choices');
assert(dashboard.includes('root.mediaAlternativePlayerCount === 1'),
  'a single alternative is presented as a direct-switch control');
assert(dashboard.includes('root.activateDashboardMediaSourceControl()'),
  'the direct button and multi-source button share one activation path');
assert(dashboard.includes('id: mediaSourceAlternativesFlow')
  && dashboard.includes('root.mediaSourcePickerExpanded')
  && dashboard.includes('root.mediaAlternativePlayerCount : 0')
  && dashboard.includes('root.mediaAlternativePlayers[index]')
  && !dashboard.includes('model: root.mediaAlternativePlayers'),
  'multiple alternatives expand as an inline Flow with stable delegate identity across polling');
assert(!dashboard.includes('implicitHeight: childrenRect.height'),
  'Flow keeps its read-only calculated implicitHeight instead of assigning it');
assert(!dashboard.includes('mediaSourcePopup') && !dashboard.includes('mediaSourceList'),
  'the alternatives list no longer uses the former popup/list controls');
assert(dashboard.includes('property real animatedHeight: targetHeight')
  && dashboard.includes('Behavior on animatedHeight')
  && dashboard.includes('Behavior on opacity')
  && dashboard.includes('Behavior on y'),
  'inline alternatives reveal and collapse with size, fade, and slide animations');
assert(dashboard.includes('root.selectDashboardMediaSource(backendId)'),
  'inline alternatives explicitly select their backend');
assert(dashboard.includes('root.mediaSourcePickerExpanded = false'),
  'successful selection collapses the inline alternatives');
assert(dashboard.includes('root.mediaAlternativePlayerCount <= 1'),
  'the inline list closes when the number of alternatives falls to one or zero');
assert(dashboard.includes('root.mediaSourcePickerExpanded = false')
  && dashboard.includes('onOpenChanged: {'),
  'the inline list is reset when Dashboard closes');
assert(dashboard.includes('togglePlaybackForBackend(backend)')
  && dashboard.includes('seekToPercentForBackend(backend, target, duration)'),
  'Dashboard transport controls target the selected backend');

// Exercise the actual JavaScript method bodies from Player.qml, not a duplicate
// test implementation. Selection must survive a repeated scan and one transient
// miss, then fall back after the next consecutive miss; switching remains usable.
const playerRoot = {
  dashboardPlayers: [],
  dashboardSelectedBackend: '',
  dashboardSelectedSnapshot: null,
  dashboardSelectedMissingPolls: 0
};
const setPlayers = new Function('root', 'value', functionBody(player, 'function setDashboardPlayers(value)'));
const selectPlayer = new Function('root', 'backendValue', functionBody(player, 'function selectDashboardPlayer(backendValue)'));
const sourceA = { player: 'deadbeef', first_line: 'A' };
const sourceB = { player: 'spotify', first_line: 'B' };
const sourceC = { player: 'mopidy', first_line: 'C' };
setPlayers(playerRoot, [sourceA, sourceB, sourceC]);
assert.equal(selectPlayer(playerRoot, 'spotify'), true, 'first backend selection succeeds');
setPlayers(playerRoot, [sourceA, sourceB, sourceC]);
assert.equal(playerRoot.dashboardSelectedBackend, 'spotify', 'selection survives regular refresh');
assert.equal(selectPlayer(playerRoot, 'mopidy'), true, 'second selection succeeds after refresh');
setPlayers(playerRoot, [sourceA, sourceB]);
assert.equal(playerRoot.dashboardSelectedBackend, 'mopidy', 'one transient missing scan does not clear selection');
assert.ok(playerRoot.dashboardPlayers.some(item => item.player === 'mopidy'),
  'last selected snapshot remains available during one transient miss');
setPlayers(playerRoot, [sourceA, sourceB]);
assert.equal(playerRoot.dashboardSelectedBackend, '', 'selection falls back after repeated absence');
assert.equal(selectPlayer(playerRoot, 'spotify'), true, 'picker can switch again after fallback');

// Exercise the Dashboard's actual choice derivation and direct-switch handlers.
const alternativesBody = functionBody(dashboard, 'readonly property var mediaAlternativePlayers:');
const getAlternatives = new Function('root', alternativesBody);
const dashboardRoot = {
  mediaBackendId: 'deadbeef',
  playerSource: { dashboardPlayers: [sourceA, sourceB, sourceC] },
  mediaSourcePickerExpanded: false,
  mediaAlternativePlayerCount: 2,
  mediaSourceSwitchSupported: true,
  selectDashboardMediaSource(backend) {
    const found = this.playerSource.dashboardPlayers.some(item => item.player === backend);
    if (!found) return false;
    this.mediaBackendId = backend;
    this.mediaSourcePickerExpanded = false;
    return true;
  }
};
assert.deepEqual(getAlternatives(dashboardRoot).map(item => item.player), ['spotify', 'mopidy'],
  'alternative set excludes the currently active backend');
dashboardRoot.mediaBackendId = 'spotify';
assert.deepEqual(getAlternatives(dashboardRoot).map(item => item.player), ['deadbeef', 'mopidy'],
  'the alternative set updates after switching and excludes the new active backend');
const activateSourceControl = new Function('root', functionBody(dashboard, 'function activateDashboardMediaSourceControl()'));
dashboardRoot.mediaAlternativePlayerCount = 1;
dashboardRoot.mediaAlternativePlayers = [{ player: 'deadbeef' }];
assert.equal(activateSourceControl(dashboardRoot), true, 'single-alternative button activates');
assert.equal(dashboardRoot.mediaBackendId, 'deadbeef', 'single-alternative button switches directly');
dashboardRoot.mediaAlternativePlayerCount = 2;
dashboardRoot.mediaSourcePickerExpanded = false;
assert.equal(activateSourceControl(dashboardRoot), true, 'multi-alternative button activates');
assert.equal(dashboardRoot.mediaSourcePickerExpanded, true, 'multi-alternative button expands inline choices');
assert.equal(activateSourceControl(dashboardRoot), true, 'multi-alternative button remains reusable');
assert.equal(dashboardRoot.mediaSourcePickerExpanded, false, 'multi-alternative button collapses inline choices');

console.log('Dashboard player alternatives, inline picker, and repeated source selection: OK');
NODE
