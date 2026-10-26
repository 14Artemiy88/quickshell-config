#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'NODE_TEST'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
let source = fs.readFileSync(path.join(root, 'js/settings/SettingsProfiles.js'), 'utf8');
source = source.replace(/^\.pragma library\s*/, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.expandStoredSettings = expandStoredSettings;', context);
const owner = {
  profileDefaults: {
    animationTimerVisibilityStyle: 'fade',
    animationTimerOptionsVisibilityStyle: 'fade',
    colors: { accent: '#ffffff' }
  },
  colorNames: ['accent']
};
const oldStored = {
  settingsPersistenceFormat: 'profile-overrides-v1',
  profileStorageFormat: 'sparse-v1',
  activeProfile: 'Work',
  profiles: { Work: { animationTimerVisibilityStyle: 'slideLeft', colors: { accent: '#ffffff' } } },
  profileOverrides: { animationTimerVisibilityStyle: 'slideRight' }
};
const migrated = context.expandStoredSettings(owner, oldStored);
assert.strictEqual(migrated.profiles.Work.animationTimerOptionsVisibilityStyle, 'slideLeft', 'old saved profile should migrate its shared animation style');
assert.strictEqual(migrated.animationTimerOptionsVisibilityStyle, 'slideRight', 'old unsaved override should migrate to the active popup style');
const newStored = {
  settingsPersistenceFormat: 'profile-overrides-v1',
  settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1',
  activeProfile: 'Work',
  profiles: { Work: { animationTimerVisibilityStyle: 'slideLeft', colors: { accent: '#ffffff' } } },
  profileOverrides: {}
};
const current = context.expandStoredSettings(owner, newStored);
assert.strictEqual(current.animationTimerOptionsVisibilityStyle, 'fade', 'new schema keeps timer widget and options-popup styles independent');
assert.strictEqual(current.profiles.Work.animationTimerOptionsVisibilityStyle, undefined, 'new sparse profiles omit the default popup style override');
console.log('Timer options animation schema migration preserves old styles and new independence: OK');
NODE_TEST
