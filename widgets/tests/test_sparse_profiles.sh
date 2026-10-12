#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const root = process.argv[2];
const src = fs.readFileSync(path.join(root, 'js/settings/SettingsProfiles.js'), 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(src, context, { filename: 'SettingsProfiles.js' });
const defaults = {
  font: 'JetBrainsMono Nerd Font',
  fontSize: 12,
  modules: { player: true, mopidy: false, cava: true },
  moduleFrames: { player: true, mopidy: false },
  geometry: { player: [1, 2, 300, 180], mopidy: [5, 6, 300, 200] },
  colors: { accent: '#00cccc', text: '#ffffff' },
  activeTheme: '14 Theme'
};
const current = {
  ...defaults,
  weatherToken: 'not-profile-scoped',
  fontSize: 15,
  modules: { player: true, mopidy: true, cava: true },
  moduleFrames: { player: false, mopidy: false },
  geometry: { player: [1, 2, 300, 180], mopidy: [10, 20, 300, 200] },
  colors: { accent: '#ff00cccc', text: '#ffffff' },
  activeTheme: '14 Theme'
};
const delta = context.diffValue(defaults, Object.fromEntries(Object.entries(current).filter(([k]) => k !== 'weatherToken')));
const expanded = context.mergeValue(defaults, delta);
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded)), Object.fromEntries(Object.entries(current).filter(([k]) => k !== 'weatherToken')));
assert(!Object.prototype.hasOwnProperty.call(delta, 'font'));
assert.strictEqual(delta.fontSize, 15);
assert(!Object.prototype.hasOwnProperty.call(delta, 'activeTheme'));
assert.strictEqual(delta.modules.mopidy, true);
assert.strictEqual(delta.geometry.mopidy[0], 10);
assert.strictEqual(delta.colors.accent, '#ff00cccc');
assert(!Object.prototype.hasOwnProperty.call(delta, 'weatherToken'));
const replacement = context.diffValue({ a: 1, b: 2 }, { b: 2 });
assert.deepStrictEqual(JSON.parse(JSON.stringify(context.mergeValue({ a: 1, b: 2 }, replacement))), { b: 2 });
const owner = {
  profileDefaults: defaults,
  profileStorageFormat: 'sparse-v1',
  profiles: { demo: delta },
  activeProfile: 'demo',
  snapshotObject: () => current,
  applyObject: (obj) => { owner.applied = obj; },
  rebuildProfileList: () => {},
  save: () => {},
  profilesRevision: 0
};
const loaded = context.expandedProfileByName(owner, 'demo');
assert.deepStrictEqual(JSON.parse(JSON.stringify(loaded)), JSON.parse(JSON.stringify(expanded)));
console.log('sparse profiles: OK');
JS
