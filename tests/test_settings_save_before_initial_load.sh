#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const root = process.argv[2];
const persistencePath = path.join(root, 'js/settings/SettingsPersistence.js');
const persistenceSource = fs.readFileSync(persistencePath, 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(persistenceSource, context, {filename: 'SettingsPersistence.js'});

let savedSignals = 0;
const writer = { running: false, payload: 'untouched' };
const owner = {
  loaded: false,
  pendingWriteRequested: false,
  writer,
  saved() { savedSignals++; },
  profileStorageFormat: 'legacy',
  moduleNames: [],
  colorNames: [],
  timerPresetDefaults: [5, 7, 15],
  profiles: { day: { fontSize: 12 } },
  activeProfile: 'day',
  customThemes: {},
  activeTheme: '14 Theme',
  moduleFrames: { launcher: true },
  moduleBackgrounds: { launcher: true },
  moduleMonitors: {},
  geometry: { launcher: [10, 20, 700, 600] },
  settingsGeometry: [640, 40, 560, 850],
  settingsMonitorName: 'DP-1'
};
const config = { launcherItemRadius: 7, launcherTitleY: 4 };

// Interaction before startup load must request a deferred write, not start one.
context.save(owner, config);
assert.strictEqual(writer.running, false, 'save before initial load must not start a writer');
assert.strictEqual(writer.payload, 'untouched', 'save before initial load must not replace the pending/unknown disk state');
assert.strictEqual(owner.pendingWriteRequested, true, 'pre-load save should be queued');
assert.strictEqual(savedSignals, 1, 'save feedback signal should still be emitted');

// Simulate the loader applying the disk snapshot and a user value settling in memory.
owner.loaded = true;
config.launcherItemRadius = 13;
owner.activeProfile = 'night';
assert.strictEqual(context.flushPendingWrite(owner, config), true, 'queued save should flush after load');
assert.strictEqual(writer.running, true, 'flush should start exactly one write');
assert.strictEqual(owner.pendingWriteRequested, false, 'flush should clear the queued flag');
let payload = JSON.parse(writer.payload);
const payloadOverrides = value => value.profileOverrides && value.profileOverrides.__profile_replace__ ? value.profileOverrides.__profile_replace__ : (value.profileOverrides || {});
assert.strictEqual(payload.settingsPersistenceFormat, 'profile-overrides-v1', 'write should use compact profile-overlay storage');
assert.strictEqual(payloadOverrides(payload).launcherItemRadius, 13, 'latest UI values should be captured as an override');
assert.strictEqual(payload.activeProfile, 'night', 'latest active profile should be captured');
assert.strictEqual(payload.profileStorageFormat, 'sparse-v1', 'write should use canonical profile format');

// A pending request during an active write must retain the newest complete state.
writer.running = true;
context.save(owner, {...config, launcherItemRadius: 19});
assert.strictEqual(owner.pendingWriteRequested, true, 'save during a write must queue a fresh snapshot');
assert.strictEqual(payloadOverrides(JSON.parse(writer.payload)).launcherItemRadius, 13, 'in-flight payload must not be mutated');
writer.running = false;
assert.strictEqual(context.flushPendingWrite(owner, {...config, launcherItemRadius: 19}), true, 'latest queued snapshot should flush');
payload = JSON.parse(writer.payload);
assert.strictEqual(payloadOverrides(payload).launcherItemRadius, 19, 'queued write must capture the latest state as an override');

const qml = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
assert(/onLoadedChanged:\s*\{\s*if \(root\.loaded\)\s*root\.flushPendingWrite\(\)/.test(qml), 'QML must flush queued saves when startup load completes');
assert(/function flushPendingWrite\(\)[\s\S]*SettingsPersistence\.flushPendingWrite\(root, Config\)/.test(qml), 'QML must delegate queued writes to persistence helper');
assert(/onExited:\s*function\(exitCode\)[\s\S]*writeProc\.finalizeWriteIfReady\(\)/.test(qml), 'writer exit must flow through completion reconciliation');
assert(/function finalizeWriteIfReady\(\)[\s\S]*root\.flushPendingWrite\(\)/.test(qml), 'writer completion must flush a queued newest snapshot after token state is reconciled');
assert(qml.includes('root.persistedWeatherToken = String(root.weatherToken || "").trim()'), 'startup load must seed the persisted weather-token baseline');
console.log('Settings startup-save race: OK');
JS
