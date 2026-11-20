#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
node - "$PROFILES" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8')
  .replace(/^\.pragma library\s*/, '')
  .replace(/^\.import .*\n/gm, '');
const context = vm.createContext({});
vm.runInContext(source, context, { filename: process.argv[2] });
const owner = { profileDefaults: { launcherCustomActions: [] }, colorNames: [] };
const stored = {
  settingsPersistenceFormat: 'profile-overrides-v1',
  profileStorageFormat: 'sparse-v1',
  settingsSchemaVersion: 1,
  activeProfile: 'hide_NW',
  profiles: {
    hide_NW: { launcherCustomActions: [{ id: 'old', enabled: true, name: 'tttt', command: 'old-command' }] }
  },
  profileOverrides: {
    launcherCustomActions: [{ id: 'new', enabled: true, name: 'qqq', command: 'new-command' }]
  }
};
const effective = context.expandStoredSettings(owner, stored);
assert.deepStrictEqual(JSON.parse(JSON.stringify(effective.launcherCustomActions.map(x => x.name))), ['qqq'],
  'array override replaces the active profile baseline; it is not concatenated');
assert.strictEqual(effective.profiles.hide_NW.launcherCustomActions[0].name, 'tttt',
  'profile baseline remains stored so reset can restore it');
const afterReset = context.expandStoredSettings(owner, { ...stored, profileOverrides: {} });
assert.deepStrictEqual(JSON.parse(JSON.stringify(afterReset.launcherCustomActions.map(x => x.name))), ['tttt'],
  'resetting the launcher scope restores the saved profile baseline');
JS
printf 'custom action arrays use profile baseline plus atomic override/reset semantics: OK\n'
