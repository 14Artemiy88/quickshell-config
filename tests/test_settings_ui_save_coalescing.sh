#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context, {filename: 'SettingsPersistence.js'});
let savedSignals = 0;
const writer = {running: true, payload: JSON.stringify({launcherItemRadius: 0}), tokenBaseline: 'token-0', tokenRequested: 'token-0'};
const owner = {
  loaded: true,
  pendingWriteRequested: false,
  writer,
  saved() { savedSignals++; },
  profileStorageFormat: 'sparse-v1',
  moduleNames: ['time'], colorNames: [],
  timerPresetDefaults: [5, 7, 15],
  profiles: {day: {fontSize: 12}, night: {fontSize: 14}},
  activeProfile: 'day',
  customThemes: {}, activeTheme: '14 Theme',
  moduleFrames: {launcher: true}, moduleBackgrounds: {launcher: true}, moduleMonitors: {},
  geometry: {launcher: [20, 30, 720, 640]},
  settingsGeometry: [640, 40, 560, 850], settingsMonitorName: 'DP-1',
  weatherToken: 'token-0', persistedWeatherToken: 'token-0'
};
const config = {launcherItemRadius: 4, launcherTitleY: 0, font: 'A'};
context.save(owner, config);
assert.strictEqual(owner.pendingWriteRequested, true, 'first save during an active write should queue a newer snapshot');
assert.strictEqual(writer.payload, JSON.stringify({launcherItemRadius: 0}), 'in-flight payload must remain immutable');
config.font = 'B'; config.launcherItemRadius = 8; owner.activeProfile = 'night';
context.save(owner, config);
config.font = 'C'; config.launcherItemRadius = 11; owner.activeProfile = 'day';
context.save(owner, config);
assert.strictEqual(owner.pendingWriteRequested, true, 'multiple saves should collapse into a queued latest snapshot');
assert.strictEqual(writer.payload, JSON.stringify({launcherItemRadius: 0}), 'queued changes must not mutate the active process payload');
writer.running = false;
assert.strictEqual(context.flushPendingWrite(owner, config), true, 'latest queued snapshot should launch after the active write');
let payload = JSON.parse(writer.payload);
assert.strictEqual(payload.launcherItemRadius, 11, 'coalesced write must capture the latest launcher value');
assert.strictEqual(payload.font, 'C', 'coalesced write must capture the latest text setting');
assert.strictEqual(payload.activeProfile, 'day', 'latest profile selection must be preserved');
assert.strictEqual(owner.pendingWriteRequested, false, 'the queued flag should clear after starting the latest snapshot');
// Queue another burst while the second write is active, then confirm only the
// last full state is captured when that write completes.
config.launcherItemRadius = 15; owner.activeProfile = 'night'; context.save(owner, config);
config.launcherItemRadius = 19; owner.activeProfile = 'day'; context.save(owner, config);
assert.strictEqual(owner.pendingWriteRequested, true, 'second burst should queue');
writer.running = false;
assert.strictEqual(context.flushPendingWrite(owner, config), true, 'second coalesced write should start');
payload = JSON.parse(writer.payload);
assert.strictEqual(payload.launcherItemRadius, 19, 'second burst must persist its last launcher value');
assert.strictEqual(payload.activeProfile, 'day', 'second burst must persist its last profile');
assert.strictEqual(savedSignals, 5, 'each user save request should still emit save feedback');
const qml = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
assert(qml.includes('if (String(root.weatherToken || "").trim() === requestedToken)'), 'late save responses must not overwrite a newer UI token edit');
console.log('Settings UI save coalescing and latest-snapshot ordering: OK');
JS
