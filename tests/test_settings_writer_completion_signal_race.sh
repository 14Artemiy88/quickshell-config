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

function makeOwner() {
  const writer = {
    running: false,
    processExited: false,
    tokenOutputFinished: false,
    writerExitCode: 0,
    commandMode: 'set-json-ui',
    payload: JSON.stringify({revision: 1}),
    tokenBaseline: 'baseline-1',
    tokenRequested: 'baseline-1',
    tokenResult: 'baseline-1'
  };
  const owner = {
    loaded: true,
    pendingWriteRequested: false,
    writer,
    savedCount: 0,
    saved() { this.savedCount++; },
    profileStorageFormat: 'sparse-v1',
    moduleNames: [], colorNames: [], timerPresetDefaults: [],
    profiles: {}, activeProfile: 'default', customThemes: {}, activeTheme: '14 Theme',
    moduleFrames: {}, moduleBackgrounds: {}, moduleMonitors: {}, geometry: {},
    settingsGeometry: [], settingsMonitorName: '', weatherToken: 'baseline-1', persistedWeatherToken: 'baseline-1'
  };
  return {owner, writer};
}

for (const signalOrder of ['process-exit-first', 'stdout-first']) {
  const {owner, writer} = makeOwner();
  const config = {launcherItemRadius: 4, font: 'initial'};
  if (signalOrder === 'process-exit-first') {
    writer.processExited = true;
    writer.tokenOutputFinished = false;
  } else {
    writer.processExited = false;
    writer.tokenOutputFinished = true;
  }

  config.font = 'newest-' + signalOrder;
  context.save(owner, config);
  assert.strictEqual(owner.pendingWriteRequested, true, `${signalOrder}: save must be queued until both completion signals arrive`);
  assert.strictEqual(writer.payload, JSON.stringify({revision: 1}), `${signalOrder}: the prior process payload must remain untouched`);
  assert.strictEqual(writer.tokenBaseline, 'baseline-1', `${signalOrder}: prior token baseline must not be reset`);
  assert.strictEqual(context.flushPendingWrite(owner, config), false, `${signalOrder}: pending snapshot must not start before finalization`);

  // This mirrors finalizeWriteIfReady after both QML callbacks have fired.
  writer.processExited = false;
  writer.tokenOutputFinished = false;
  assert.strictEqual(context.flushPendingWrite(owner, config), true, `${signalOrder}: newest queued snapshot should start once finalized`);
  const payload = JSON.parse(writer.payload);
  assert.strictEqual(payload.font, 'newest-' + signalOrder, `${signalOrder}: queued write must include the latest setting`);
  assert.strictEqual(writer.running, true, `${signalOrder}: queued writer should now be active`);
}

console.log('Settings writer process/stdout completion race: OK');
JS
